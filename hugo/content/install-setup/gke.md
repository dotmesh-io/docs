+++
draft = false
title = "Install on GKE"
synopsis = "Installing Dotmesh on a GKE cluster"
knowledgelevel = ""
date = 2017-12-22T11:27:29Z
weight = "5"
[menu]
  [menu.main]
    parent = "install-setup"
+++

{{% overview %}}
* An account on the [Google Cloud Console](https://console.cloud.google.com)
* The [Cloud SDK](https://cloud.google.com/sdk/downloads) (with the `gcloud` command)
* `kubectl` installed: given the Cloud SDK, run `gcloud components install kubectl`
* GKE activated on the [console page](https://console.cloud.google.com/kubernetes/list)
{{% /overview %}}

This guide will show you how to install dotmesh onto a Kubernetes
cluster provisioned on [Google Kubernetes
Engine](https://cloud.google.com/kubernetes-engine/). We support
Kubernetes 1.7, 1.8 and 1.9 GKE clusters, **only if they are running the Ubuntu image type**.

## Authenticate

First - let's authenticate our `gcloud` cli and point to the correct project.

Change the value of `my-gcloud-project` to your active project id:

```plain
export GCLOUD_PROJECT=my-gcloud-project
```

Then we use the `gcloud` cli to authenticate:

{{< copyable name="step-01" >}}
gcloud auth login
gcloud config set project $GCLOUD_PROJECT
{{< /copyable >}}

## Provision cluster

Then we provision a new Kubernetes cluster of 3 nodes:

{{< copyable name="step-02" >}}
gcloud container clusters create dotmesh-gke-cluster \
  --image-type=ubuntu \
  --tags=dotmesh \
  --machine-type=n1-standard-4 \
  --cluster-version=1.9.6-gke.1 \
  --num-nodes 3
{{< /copyable >}}

**NOTE** - At present the cluster needs to use `--image-type=ubuntu` - in upcoming releases this requirement will be removed.

You can run the following command to list the available cluster versions for GKE.  You can choose a version that suits you as long as it is `>= 1.8.X`

```plain
gcloud container get-server-config
```

Then open port `32607` so external `dm` clients can communicate with our cluster.
Also, we open `30004` as we use that in later examples.

{{< copyable name="step-03" >}}
gcloud compute firewall-rules create dotmesh-ingress \
  --allow tcp:32607,tcp:30004 \
  --target-tags=dotmesh
{{< /copyable >}}

**NOTE** - The need for a firewall rule will be replaced with an ingress rule in an upcoming release

## Cluster Admin Role

We need to ensure that we are known to the Kubernetes cluster as an administrator - to do this, we create a `cluster-admin` binding for our user:

{{< copyable name="step-03" >}}
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user "$(gcloud config get-value core/account)"
{{< /copyable >}}

If this doesn't work straight away, wait a few minutes and try again.
It might just be that your Kubernetes cluster is warming up.

## Create namespace & secrets

Before we can install Dotmesh, we need to set our admin password and api key:

```plain
export ADMIN_PASSWORD=applesinsecurePassword123
export ADMIN_API_KEY=applesinsecurePassword123
```

Then we create the namespace before adding our credentials as secrets:

{{< copyable name="step-04" >}}
kubectl create namespace dotmesh
echo -n $ADMIN_PASSWORD > dotmesh-admin-password.txt
echo -n $ADMIN_API_KEY > dotmesh-api-key.txt
kubectl create secret generic dotmesh \
  --from-file=./dotmesh-admin-password.txt \
  --from-file=./dotmesh-api-key.txt -n dotmesh
rm -f dotmesh-admin-password.txt dotmesh-api-key.txt
{{< /copyable >}}

## Etcd operator

Install the etcd operator ready for our dotmesh cluster:

{{< copyable name="step-05" >}}
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml
{{< /copyable >}}

It may take a few minutes for the etcd operator to activate.
Use `kubectl get pods -n dotmesh` to check for a running `etcd-operator` pod.

## Create an etcd cluster for dotmesh to use

{{< copyable name="step-05a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-etcd-cluster.yaml
{{< /copyable >}}

```plain
etcdcluster "dotmesh-etcd-cluster" configured
```

## Dotmesh

Use the following command to apply the YAML for the ConfigMap:

{{< copyable name="step-06" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.gke.yaml
{{< /copyable >}}

Use the following command to apply the YAML for running dotmesh on Kubernetes 1.8 and 1.9:

{{< copyable name="step-06a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

If you're running Kubernetes 1.7 on your cluster, you must use a different YAML:

{{< copyable name="step-06b" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml
{{< /copyable >}}

```plain
serviceaccount "dotmesh" configured
serviceaccount "dotmesh-operator" configured
clusterrole "dotmesh" configured
clusterrolebinding "dotmesh" configured
clusterrolebinding "dotmesh-operator" configured
service "dotmesh" configured
deployment "dotmesh-operator" configured
serviceaccount "dotmesh-provisioner" configured
clusterrole "dotmesh-provisioner-runner" configured
clusterrolebinding "dotmesh-provisioner" configured
deployment "dotmesh-dynamic-provisioner" configured
storageclass "dotmesh" configured
```

Let's check to see that we have our dotmesh pods running on our Kubernetes cluster.  They might take a few moments to get going - wait for the pods to start before proceeding.

{{< copyable name="step-01" >}}
kubectl get po -n dotmesh
{{< /copyable >}}

```plain
NAME                                           READY     STATUS        RESTARTS   AGE
dotmesh-dynamic-provisioner-7b766c4f7f-hkjkl     1/1       Running       0          1h
dotmesh-etcd-cluster-0000                        1/1       Running       0          1h
dotmesh-etcd-cluster-0001                        1/1       Running       0          1h
dotmesh-etcd-cluster-0002                        1/1       Running       0          1h
dotmesh-operator-7ff894567-mx75b                 1/1       Running       0          1h
server-gke-mycluster-default-pool-11111111-d4j9a 1/1       Running       0          1h
server-gke-mycluster-default-pool-11111111-5hg2g 1/1       Running       0          1h
server-gke-mycluster-default-pool-11111111-6fthj 1/1       Running       0          1h
etcd-operator-56b49b7ffd-529zn                   1/1       Running       0          1h
```

## Restart Kubelet (Kubernetes 1.7 only)

If you are running Kubernetes 1.7, then to get the kubelet to pick up
the flexvolume driver dotmesh just installed - run this script that
logs in to each of the nodes and restarts the kubelet process:

{{< copyable name="step-01" >}}
for node in $(kubectl get no | tail -n +2 | awk '{print $1}'); do
  gcloud compute ssh $node --command "sudo systemctl restart kubelet"
done
{{< /copyable >}}

## Customising the installation

If you want a non-default installation - for instance, only running
Dotmesh on those of your nodes that have capacious fast disks, as
those are the only ones where stateful containers will reside - the
YAML we supply is easy to customise. Check out the [Kubernetes YAML
reference guide](/references/kubernetes/) for the full run-down!

## Using the `dm` client to control Dotmesh

In order to manage branches and commits, push and pull dots, and so
on, you'll need to connect the `dm` client to your Kubernetes-hosted
Dotmesh cluster. To do that, you'll need the API key you chose in the
setup phase, and the hostname of a node in the cluster:

{{< copyable name="step-07" >}}
export NODE_IP=$(kubectl get no -o wide | tail -n 1 | awk '{print $6}')
dm remote add gke admin@$NODE_IP
{{< /copyable >}}

```plain
API key: Paste your API key here, it won't be echoed!

Remote added.
```

The `gke` part is just a name for this cluster that you'll use in
subsequent [dm remote
commands](/references/cli/#connecting-to-clusters), so pick something
that describes it.

You can then switch to that remote, and use it:


{{< copyable name="step-08" >}}
dm remote switch gke
dm list
{{< /copyable >}}

## What's next?

* [Hello Dotmesh on Kubernetes](/tutorials/hello-dotmesh-kubernetes/).
* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
* [Kubernetes YAML reference guide](/references/kubernetes/)
* [Command Line Reference](/references/cli/)
