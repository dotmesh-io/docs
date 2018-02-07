+++
draft = false
title = "Install on Kubernetes on Docker for Mac"
synopsis = "Installing Dotmesh on Kubernetes on Docker for Mac"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
weight = "3"
[menu]
  [menu.main]
    parent = "install-setup"
+++

## DOES NOT WORK YET

Sorry, this guide doesn't work yet.
It should start working when [#263](https://github.com/dotmesh-io/dotmesh/issues/263) and [#268](https://github.com/dotmesh-io/dotmesh/issues/268) are fixed.


## ARE YOU SURE YOU WANT TO READ IT ANYWAY?

{{% overview %}}
* [Edge build of Docker for Mac](https://docs.docker.com/docker-for-mac/install/) with [Kubernetes enabled](https://docs.docker.com/docker-for-mac/#kubernetes).
{{% /overview %}}


## Check Kubernetes on Docker for Mac is working

{{< copyable name="step-01" >}}
kubectl config current-context
{{< /copyable >}}

Should show:
```plain
docker-for-desktop
```

If it doesn't, check the [Docker for Mac docs on Kubernetes](https://docs.docker.com/docker-for-mac/#kubernetes).
Also make sure you don't have a `KUBECONFIG` environment variable set.

## Installing Dotmesh on Kubernetes

Before we can install Dotmesh, we need to set out admin password and api key:

```plain
export ADMIN_PASSWORD=apples
export ADMIN_API_KEY=apples
```

You may want to use stronger credentials than `apples`.


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

## Dotmesh

With the etcd operator loaded into your cluster, installing Dotmesh is
a simple matter of loading the Dotmesh YAML:

{{< copyable name="step-03" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

<!--

TODO uncomment when https://github.com/dotmesh-io/dotmesh/issues/263 is fixed.

**NOTE** if you are using Kubernetes > `1.8` then use the following URL:

{{< copyable name="step-04" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

-->

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
dotmesh-5hg2g                                  1/1       Running       0          1h
dotmesh-6fthj                                  1/1       Running       0          1h
dotmesh-dynamic-provisioner-7b766c4f7f-hkjkl   1/1       Running       0          1h
dotmesh-etcd-cluster-0000                      1/1       Running       0          1h
dotmesh-etcd-cluster-0001                      1/1       Running       0          1h
dotmesh-etcd-cluster-0002                      1/1       Running       0          1h
dotmesh-rd9c4                                  1/1       Running       0          1h
etcd-operator-56b49b7ffd-529zn                 1/1       Running       0          1h
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
setup phase.

As this is a local install on Docker for Mac, we just use localhost as the hostname.

{{< copyable name="step-05" >}}
dm remote add local-kube admin@localhost
{{< /copyable >}}

```plain
API key: Paste your API key here, it won't be echoed!

Remote added.
```

You can then switch to that remote, and use it:

{{< copyable name="step-06" >}}
dm remote switch local-kube
dm list
{{< /copyable >}}

## What's next?

* [Hello Dotmesh on Kubernetes](/tutorials/hello-dotmesh-kubernetes/).
* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
* [Kubernetes YAML reference guide](/references/kubernetes/)
* [Command Line Reference](/references/cli/)
