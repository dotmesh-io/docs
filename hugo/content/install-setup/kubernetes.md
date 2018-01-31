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

Dotmesh relies on coreos etcd
[operator](https://coreos.com/blog/introducing-operators.html) to set
up our own dedicated etcd cluster in the `dotmesh` namespace. We've
mirrored a copy of the etcd operator YAML ([part
1](https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml), [part
2](https://get.dotmesh.io/yaml/etcd-operator-dep.yaml)), but it's
unmodified so feel free to use your own.

With the etcd operator loaded into your cluster, installing Dotmesh is
a simple matter of loading the Dotmesh YAML:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/dotmesh.yaml</kbd>
</pre></div>

By default, that will install Dotmesh on every node in your
cluster. Dot storage will be in a 10GiB file created in
`/var/lib/dotmesh` in the host filesystem; that's fine for light
usage, but if you are likely to have more than 10GiB of data to deal
with in total, you'll want to override that by creating a ZFS pool
called `pool` on each of your nodes before installing Dotmesh. Dotmesh
will use that pool for Dot storage if it finds it already existing at
install time.

## Customising the installation

If you want a non-default installation - for instance, only running
Dotmesh on those of your nodes that have capacious fast disks, as
those are the only ones where stateful containers will reside - the
YAML we supply is easy to customise. Check out the [Kubernetes YAML
reference guide](/references/kubernetes/) for the full run-down!
