+++
draft = false
title = "Install on generic Kubernetes"
synopsis = "Installing Dotmesh on a generic Kubernetes cluster"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "4"
[menu]
  [menu.main]
    parent = "install-setup"
+++

{{% overview %}}
* A Kubernetes cluster (version >= 1.7)
{{% /overview %}}


Before we can install Dotmesh, we need to set out admin password and api key:

```plain
export ADMIN_PASSWORD=applesinsecurePassword123
export ADMIN_API_KEY=applesinsecurePassword123
```

You may want to use stronger credentials.

## Credentials

Then we create the namespace before adding our credentials as secrets:

{{< copyable name="step-01" >}}
kubectl create namespace dotmesh
echo -n $ADMIN_PASSWORD > dotmesh-admin-password.txt
echo -n $ADMIN_API_KEY > dotmesh-api-key.txt
kubectl create secret generic dotmesh \
  --from-file=./dotmesh-admin-password.txt \
  --from-file=./dotmesh-api-key.txt -n dotmesh
rm -f dotmesh-admin-password.txt dotmesh-api-key.txt
{{< /copyable >}}

```plain
namespace "dotmesh" created
secret "dotmesh" created
```

## Etcd

Dotmesh relies on coreos etcd
[operator](https://coreos.com/blog/introducing-operators.html) to set
up our own dedicated etcd cluster in the `dotmesh` namespace. We've
mirrored a copy of the etcd operator YAML ([part
1](https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml), [part
2](https://get.dotmesh.io/yaml/etcd-operator-dep.yaml)), but it's
unmodified so feel free to use your own.

{{< copyable name="step-02" >}}
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml
{{< /copyable >}}

```plain
clusterrolebinding "dotmesh-etcd-operator" configured
deployment "etcd-operator" configured
```

It may take a few minutes for the etcd operator to activate.
Use `kubectl get pods -n dotmesh` to check for a running `etcd-operator` pod.

## Create an etcd cluster for dotmesh to use

{{< copyable name="step-02a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-etcd-cluster.yaml
{{< /copyable >}}

```plain
etcdcluster "dotmesh-etcd-cluster" configured
```

## Dotmesh

Next, you must create the ConfigMap (if you want to customise it, please see the [Kubernetes YAML reference guide](/references/kubernetes/); seriously consider using `pvcPerNode` mode for a production cluster):

{{< copyable name="step-03" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.yaml
{{< /copyable >}}

With the configmap created, installing Dotmesh is a simple matter of loading the Dotmesh YAML:

{{< copyable name="step-03a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml
{{< /copyable >}}

**NOTE** if you are using Kubernetes > `1.8` then use the following URL:

{{< copyable name="step-04" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
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

By default, that will install Dotmesh on every node in your
cluster. Dot storage will be in a 10GiB file created in
`/var/lib/dotmesh` in the host filesystem; that's fine for light
usage, but if you are likely to have more than 10GiB of data to deal
with in total, you'll want to override that by creating a ZFS pool
called `pool` on each of your nodes before installing Dotmesh. Dotmesh
will use that pool for Dot storage if it finds it already existing at
install time.

## Checking the cluster

Let's check to see that we have our dotmesh pods running.  They might take a few moments to get going - wait for the pods to start before proceeding.  Here is an example of the desired outcome on a 3 node cluster.  Your results may vary depending on your cluster size.

{{< copyable name="step-01" >}}
kubectl get po -n dotmesh
{{< /copyable >}}

```plain
NAME                                           READY     STATUS        RESTARTS   AGE
etcd-operator-56b49b7ffd-529zn                 1/1       Running       0          1h
dotmesh-etcd-cluster-0000                      1/1       Running       0          1h
dotmesh-etcd-cluster-0001                      1/1       Running       0          1h
dotmesh-etcd-cluster-0002                      1/1       Running       0          1h
dotmesh-operator-7ff894567-mx75b               1/1       Running       0          1h
server-node1                                   1/1       Running       0          1h
server-node2                                   1/1       Running       0          1h
server-node3                                   1/1       Running       0          1h
dotmesh-dynamic-provisioner-7b766c4f7f-hkjkl   1/1       Running       0          1h
```

## Restart Kubelet

To get the kubelet to pick up the flexvolume driver dotmesh just installed - log into each of the nodes and restart the kubelet process:

{{< copyable name="step-01a" >}}
sudo systemctl restart kubelet
{{< /copyable >}}

**NOTE** In Kubernetes 1.8 restarting the kubelet will not be needed

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

{{< copyable name="step-05" >}}
dm remote add NAME admin@HOSTNAME
{{< /copyable >}}

```plain
API key: Paste your API key here, it won't be echoed!

Remote added.
```

The `NAME` is just a name for this cluster that you'll use in
subsequent [dm remote
commands](/references/cli/#connecting-to-clusters), so pick something
that describes it.

You can then switch to that remote, and use it:

{{< copyable name="step-06" >}}
dm remote switch NAME
dm list
{{< /copyable >}}

## What's next?

* [Hello Dotmesh on Kubernetes](/tutorials/hello-dotmesh-kubernetes/).
* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
* [Kubernetes YAML reference guide](/references/kubernetes/)
* [Command Line Reference](/references/cli/)
