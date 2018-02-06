+++
draft = false
title = "Installing on GKE"
synopsis = "Installing Dotmesh on a GKE cluster"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "install-setup"
+++

{{% overview %}}
* An account on the [Google Cloud Console](https://console.cloud.google.com)
* The [Cloud SDK](https://cloud.google.com/sdk/downloads) (with the `gcloud` command)
* GKE activated on the [console page](https://console.cloud.google.com/kubernetes/list)
{{% /overview %}}

This guide will show you how to install dotmesh onto a Kubernetes cluster provisioned on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/).

## Authenticate

First - let's authenticate our `gcloud` cli and point to the correct project.

Change the value of `my-gcloud-project` to your active project:

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
  --cluster-version=1.8.6-gke.0
{{< /copyable >}}

**NOTE** - At present the cluster needs to use `--image-type=ubuntu` - in upcoming releases this requirement will be removed.

Then open port `6969` so external `dm` clients can communicate with our cluster:

{{< copyable name="step-03" >}}
gcloud compute firewall-rules create dotmesh-ingress \
  --allow tcp:6969 \
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

## Create namespace & secrets

Before we can install Dotmesh, we need to set out admin password and api key:

```plain
export ADMIN_PASSWORD=apples
export ADMIN_API_KEY=apples
```

Then we create the namespace before adding our credentials as secrets:

{{< copyable name="step-04" >}}
kubectl create namespace dotmesh
echo -n $ADMIN_PASSWORD > dotmesh-admin-password.txt
echo -n $ADMIN_API_KEY > dotmesh-api-key.txt
kubectl create secret generic dotmesh \
  --from-file=./dotmesh-admin-password.txt \
  --from-file=./dotmesh-api-key.txt -n dotmesh
rm dotmesh-admin-password.txt dotmesh-api-key.txt
{{< /copyable >}}

## Etcd operator

Install the etcd operator ready for our dotmesh cluster:

{{< copyable name="step-05" >}}
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml
{{< /copyable >}}

## Dotmesh

Use the following command to apply the YAML configuration for running dotmesh:

{{< copyable name="step-06" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}


```plain
etcdcluster "dotmesh-etcd-cluster" configured
serviceaccount "dotmesh" configured
clusterrole "dotmesh" configured
clusterrolebinding "dotmesh" configured
service "dotmesh" configured
daemonset "dotmesh" configured
serviceaccount "dotmesh-provisioner" configured
clusterrole "dotmesh-provisioner-runner" configured
clusterrolebinding "dotmesh-provisioner" configured
deployment "dotmesh-dynamic-provisioner" configured
storageclass "dotmesh" configured
```

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
