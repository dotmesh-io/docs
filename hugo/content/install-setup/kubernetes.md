+++
draft = false
title = "Installing on generic Kubernetes"
synopsis = "Installing Dotmesh on a generic Kubernetes cluster"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "install-setup"
+++

## Supported versions

* Kubernetes >= 1.6

## How to install Dotmesh on Kubernetes

Before we can install Dotmesh, we need to create the `dotmesh`
namespace and set up the initial admin password and API keys:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl create namespace dotmesh</kbd>
namespace "dotmesh" created
$ <kbd>echo -n '<em>Initial admin password</em>' > dotmesh-admin-password.txt</kbd>
$ <kbd>echo -n '<em>Initial admin API key</em>' > dotmesh-api-key.txt</kbd>
$ <kbd>kubectl create secret generic dotmesh --from-file=./dotmesh-admin-password.txt \
  --from-file=./dotmesh-api-key.txt -n dotmesh</kbd>
secret "dotmesh" created
$ <kbd>rm dotmesh-admin-password.txt dotmesh-api-key.txt</kbd>
</pre></div>

Dotmesh relies on coreos etcd
[operator](https://coreos.com/blog/introducing-operators.html) to set
up our own dedicated etcd cluster in the `dotmesh` namespace. We've
mirrored a copy of the etcd operator YAML ([part
1](https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml), [part
2](https://get.dotmesh.io/yaml/etcd-operator-dep.yaml)), but it's
unmodified so feel free to use your own.

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml</kbd>
clusterrolebinding "dotmesh-etcd-operator" configured
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml</kbd>
deployment "etcd-operator" configured
</pre></div>

With the etcd operator loaded into your cluster, installing Dotmesh is
a simple matter of loading the Dotmesh YAML:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/dotmesh.yaml</kbd>
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
</pre></div>

**NOTE** if you are using Kubernetes > `1.8` then use the following URL:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml</kbd>
</pre></div>

By default, that will install Dotmesh on every node in your
cluster. Dot storage will be in a 10GiB file created in
`/var/lib/dotmesh` in the host filesystem; that's fine for light
usage, but if you are likely to have more than 10GiB of data to deal
with in total, you'll want to override that by creating a ZFS pool
called `pool` on each of your nodes before installing Dotmesh. Dotmesh
will use that pool for Dot storage if it finds it already existing at
install time.

### Customising the installation

If you want a non-default installation - for instance, only running
Dotmesh on those of your nodes that have capacious fast disks, as
those are the only ones where stateful containers will reside - the
YAML we supply is easy to customise. Check out the [Kubernetes YAML
reference guide](/references/kubernetes/) for the full run-down!

### Using the `dm` client to control Dotmesh

In order to manage branches and commits, push and pull dots, and so
on, you'll need to connect the `dm` client to your Kubernetes-hosted
Dotmesh cluster. To do that, you'll need the API key you chose in the
setup phase, and the hostname of a node in the cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote add NAME admin@HOSTNAME</kbd>
API key: <kbd>Paste your API key here, it won't be echoed!</kbd>

Remote added.
</pre></div>

The `NAME` is just a name for this cluster that you'll use in
subsequent [dm remote
commands](/references/cli/#connecting-to-clusters), so pick something
that describes it.

You can then switch to that remote, and use it:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote switch NAME</kbd>
$ <kbd>dm list</kbd>
...
</pre></div>

## What's next?

* [Hello Dotmesh on Kubernetes](/tutorials/hello-dotmesh-kubernetes/).
* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
