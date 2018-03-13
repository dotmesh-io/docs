+++
draft = false
title = "Architecture"
synopsis = "The Concrete Architecture of Dotmesh"
knowledgelevel = "Advanced"
date = 2018-01-26T14:53:25Z
order = "2"
[menu]
  [menu.main]
    parent = "concepts"
+++

This guide will tell you how Dotmesh works under the hood: how all
these dots are actually stored on the nodes, and what bits of software
run where.

## Architecture diagram

{{< figure src="/hugo/concrete_architecture.png" title="dotmesh architecture, described below" link="/hugo/concrete_architecture.png" >}}


## The cluster.

Dotmesh nodes are organised into clusters.

The thing that makes a bunch of Dotmesh nodes in a cluster different
to a bunch of Dotmesh nodes *not* in a cluster is that the register of
Dots is managed by a cluster - not by a node. Any node within a
cluster sees and operates upon the same list of Dots, and Dotmesh will
move the physical data underlying the Dots between nodes in a cluster
as they're needed.

All the commits on all the branches get replicated to every node
automatically. The only thing that isn't replicated is the uncommitted
"dirty" state of each subdot on each branch; that's stored on a single
node, known as the "master node" for that branch.

We recommend that, to protect data from loss if that node is
destroyed, you commit your dots regularly so the commit gets
replicated to other nodes in the cluster! Dotmesh does not replicate
the uncommitted state of a dot.

Clusters can  come in various  different flavours, but they  all work
the same inside.

The simplest kind is a single-node Docker cluster. If you run `dm
cluster init` on your laptop to use Dotmesh with Docker, you've got a
single-node cluster. It's a single Dotmesh node doing its thing and
managing your dots for you, and you could extend it by adding other
nodes in future with `dm cluster join`.

If you do that, you now have a multi-node Docker cluster. You can
attach volumes from dots to Docker images on any node in the
cluster. and Dotmesh will automatically move the uncommitted state of
that branch of the dot to the node that you start a container on
(don't worry, it's fast because the commits are already replicated -
all it needs to move are the differences since the last commit). You
can attach subdots from the same branch to multiple containers, but
they all need to be on the same node.

You can also install Dotmesh into a Kubernetes cluster. In that case,
Kubernetes will automatically run Dotmesh on every node in the
cluster, so the Dotmesh cluster and the Kubernetes cluster become one
and the same. Just as with a Docker cluster, you can now attach
volumes from Dots into containers; but the live state of each branch
can only be on one node at a time, so if you attach multiple
containers to the same branch, they will all need to be on the same
node.

## etcd.

The mesh that weaves the nodes together in a Dotmesh cluster is
[etcd](https://coreos.com/etcd/). By default, the Dotmesh installers
start up their own etcd cluster - as a docker container called `etcd`
in raw Docker, or via an instance of the etcd operator in the
`dotmesh` namespace in Kubernetes. etcd gives us a cluster-wide
replicated database of core state; this is used for:

 * Server discovery - every node registers itself in etcd, so a list
   of running nodes is available.
 * Storing the registry of dots in the cluster, including metadata
   about branches and commits.
 * Routing requests to the master node for a branch - lots of
   inter-node communication is handled by putting a message into etcd,
   that the other nodes watch for.

## The Dotmesh server.

Every node also runs the Dotmesh server. This consists of two
containers - one called `dotmesh-server`, which is a wrapper that sets
some things up and runs `dotmesh-server-inner` where the real work
happens.

The dotmesh server communicates with the etcd instance on the node on
port 42380.

## ZFS: Dots and Subdots on disk.

Dotmesh stores Dot content in ZFS. It will use a pool called `pool`;
if one does not exist, it will create a ten GiB file called
`/var/lib/dotmesh/dotmesh_data` and use that as a ZFS pool. That's
sufficient for casual use of Dotmesh, but serious users will want to
create their own zpool called `pool`, either on a dedicated disk
partition or a larger file.

Each branch of each dot is a ZFS filesystem within the node, and each
dotmesh commit is a ZFS snapshot. When a branch is on its "master"
node, then the ZFS filesystem corresponding to that branch is directly
mountable into a container as a writable filesystem; otherwise, it's
just used as a repository of snapshots and kept read-only.

Each subdot is a subdirectory of the ZFS filesystem corresponding to
the dot. The "default subdot", used when users don't request a subdot,
just just a subdot called `__default__`. Users can directly mount the
root of the dot as a volume by asking for a subdot called
`__root__`. Subdot names starting with `_` are reserved.

## Intra-cluster communications.

Communication between Dotmesh server processes within the cluster is
via two means:

 * Shared state in etcd, which communicates between nodes using port
   42380.
 * HTTP via port 32607.

<div class="alert alertNotice"><p>WARNING: Communications via HTTP on
port 32607 aren't encrypted or protected from attackers in any
meaningful sense, so please keep those ports locked down in your
cluster and use a VPN if you're extending a cluster over untrusted
networks!</p></div>

The actual transfer of Dot contents is via HTTP on port 32607, so
that's where the bulk of the bandwidth will be - route that via a good
(and cheap for bulk!) network connection. The communications with
etcd, and between etcd nodes, are just metadata so the bandwidth usage
should be negligible, but latency may harm system response times and
etcd network outages will certain cause a (temporary) degradation of
system functionality.

## Inter-cluster communications.

Communication between your local cluster and the Hub is via HTTPS on
port 443. This includes both API traffic as documented in the [API
manual](../../references/api/), and the transfer of Dot filesystem
data. Please make sure all your Dotmesh nodes are able to connect to
`dothub.com` on port 32607 for the Hub to work correctly.

## Docker and Kubernetes.

Docker and Kubernetes both interact with the Dotmesh server on the
node where a volume attachment is requested. Dotmesh automatically
installs itself as a Docker volume plugin, and installs a Kubernetes
FlexVolume driver, on every node as part of its normal operation.

These two interfaces are simply adapters from the Docker and
FlexVolume protocols to the Dotmesh server, mounting subdots as
volumes when required. The flexvolume driver is activated when a
Kubernetes persistent volume (PV) is created using FlexVolume and
specifying the drver as `dotmesh.io/dm`.

The docker volume plugin is inside the Dotmesh server itself, while
the FlexVolume driver is an executable that gets installed into
`/usr/libexec/kubernetes/kubelet-plugins/volume/exec/dotmesh.io~dm` in
the host filesystem.

In Kubernetes clusters, there is an additional component: the dynamic
provisioner, which runs as a Kubernetes Deployment of the
`dotmesh-dynamic-provisioner` Docker image. This registers itself with
Kubernetes and detects the creation of Persistent Volume Claims (PVCs)
referencing a StorageClass that nominates the
`dotmesh/dotmesh-dynamic-provisioner` provisioner; when such PVCs are
created, it just creates a matching PV with the appropriate
settings. The dynamic provisioner is started automatically by the
default DotMesh YAML file, which also creates a StorageClass called
`dotmesh` which references the provisioner correctly.

The practical usage of these components is explained in the [Docker and
Kubernetes integration guides](/install-setup/).

## The `dm` client.

Other than asking Docker or Kubernetes to attach subdots as container
volumes, the main way users interact with Dotmesh is via the `dm`
command-line client. This communicates with the cluster via HTTP on
port 32607 (or HTTPS on port 443 when talking to the Hub), simply by
[invoking the API](../../references/api/). The one exception is when
the user performs `dm cluster init`, `dm cluster join`, `dm cluster
reset` or `dm cluster upgrade`, which also communicate with Docker and
ZFS to control Dotmesh containers and configure the ZFS pools.

Further details on the `dm` client and how it obtains the details required to invoke the API on your local cluster can be found in the [`dm` command-line reference guide](../../references/cli/)
