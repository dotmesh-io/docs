+++
draft = false
title = "Kubernetes YAML"
synopsis = "Configure Dotmesh in Kubernetes"
knowledgelevel = "Intermediate"
date = 2018-01-26T14:12:28Z
weight = "3"
[menu]
  [menu.main]
    parent = "references"
+++

This guide will explain the ins and outs of the Dotmesh Kubernetes
YAML file. It's not a guide to just using it to install and use
Dotmesh with Kubernetes - you can find that in the [Installation guide](/install-setup/kubernetes/). This guide is for
people who want to modify the YAML and do non-standard installations.

We assume you have read the [Concrete Architecture
guide](/concepts/architecture/), and understand what the
different components of a Dotmesh cluster are.

## Using customised YAML.

The Dotmesh YAML is split between two files.

The first file is a ConfigMap that, as you might expect, provides
configuration used by the Dotmesh Operator to configure Dotmesh on
your cluster; that's the one you're most likely to need to modify.

The second file actually sets up the components of the cluster, and is
less likely to need changing. However, this guide will explain both in
detail, to enable customised setups.

We provide pre-customised versions of both YAML files:

### ConfigMap

* [Vanilla ConfigMap](https://get.dotmesh.io/yaml/configmap.yaml)
* [GKE (Google) ConfigMap](https://get.dotmesh.io/yaml/configmap.gke.yaml)
* [AKS (Azure) ConfigMap](https://get.dotmesh.io/yaml/configmap.aks.yaml)

### Core YAML

* [Core YAML for Kubernetes 1.7](https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml)
* [Core YAML for Kubernetes 1.8](https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml)
* [Core YAML for Kubernetes 1.8 on AKS (Azure)](https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.aks.yaml)

### Getting the YAML ready for customisation

Grab the most appropriate base YAML for your situation, and customise it like so:

<div class="highlight"><pre class="chromaManual">
$ <kbd>curl https://get.dotmesh.io/yaml/configmap.yaml > configmap-default.yaml</kbd>
$ <kbd>curl https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml > dotmesh-default.yaml</kbd>
$ <kbd>cp configmap-default.yaml configmap-customised.yaml</kbd>
$ <kbd>cp dotmesh-default.yaml dotmesh-customised.yaml</kbd>
# ...edit configmap-customised.yaml and/or dotmesh-customised.yaml...
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/configmap-customised.yaml</kbd>
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-customised.yaml</kbd>
</pre></div>

## The ConfigMap

The ConfigMap has the following keys in its `data` section:

* `nodeSelector`: A selector for the nodes that should run Dotmesh. If it's left as the empty string, then Dotmesh will be installed on every node.
* `upgradesUrl`: The URL of the checkpoint server. The Dotmesh server on each node will periodically ping an API call to this URL to find out if a new version is available; if so, a message will be presented to users when they run `dm version`. To turn this off so that we don't know you're running Dotmesh, set it to the empty string.
* `upgradesIntervalSeconds`: How many seconds to wait between checks of the checkpoint server.
* `flexvolumeDriverDir`: The directory on the nodes (in the host filesystem) where flexdriver plugins need to be installed. This varies between cloud providers; this is the line that changes between the vanilla, GKE and AKS versions of the ConfigMap YAML.
* `poolName`: The name of the ZFS pool to use for backend storage.
* `logAddress`: The IP address of a syslog server to send log messages to. If left as the empty string, then logging will go to standard output (which means is recommended).
* `storageMode`: This is reserved for future expansion. Leave it as `local` ([for now...](https://github.com/dotmesh-io/dotmesh/issues/401)).
* `local.poolSizePerNode`: How large a pool file to create on each node. Defaults to `10G` for a ten gigabyte pool.
* `local.poolLocation`: The location on the host filesystem where the pool file will be created.

## Components of the Core YAML.

The YAML is a List, composed of a series of different objects. We'll
summarise them, then look at each in detail.

All namespaced objects are in the `dotmesh` namespace; but
ClusterRoles, ClusterRoleBindings and StorageClasses are not
namespaced in Kubernetes.

The following objects comprise the core Dotmesh cluster:

* The `dotmesh` ServiceAccount
* The `dotmesh-operator` ServiceAccount
* The `dotmesh` ClusterRole
* The `dotmesh` ClusterRoleBinding
* The `dotmesh-operator` ClusterRoleBinding
* The `dotmesh` Service
* The `dotmesh-operator` Deployment

Then the following comprise the Dynamic Provisioner:

 * The `dotmesh-provisioner` ServiceAccount
 * The `dotmesh-provisioner-runner` ClusterRole
 * The `dotmesh-provisioner` ClusterRoleBinding
 * The `dotmesh-dynamic-provisioner` Deployment
 * The `dotmesh` StorageClass

## The `dotmesh-etcd-cluster` etcd cluster.

We use the coreos etcd
[operator](https://coreos.com/blog/introducing-operators.html) to set
up our own dedicated etcd cluster in the `dotmesh` namespace. Please
consult the [operator
documentation](https://coreos.com/blog/introducing-the-etcd-operator.html)
to learn how to customise it.

## The `dotmesh` ServiceAccount.

This is the ServiceAccount that will be used to run the Dotmesh
server. You shouldn't need to change this.

## The `dotmesh-operator` ServiceAccount.

This is the ServiceAccount that will be used to run the Dotmesh
operator. You shouldn't need to change this.

## The `dotmesh` ClusterRole.

This is the role Dotmesh will run under. You shouldn't need to change this file.

If you are running Kubernetes >= `1.8` then RBAC is probably enabled and you need to create a `cluster-admin` role for your cluster.

Here is an example of adding that role for a gcloud user running a GKE cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user "$(gcloud config get-value core/account)"</kbd>
</pre></div>

The `--user` can be replaced with a local user (e.g. `root`) or another user depending on where your cluster is deployed.

## The `dotmesh` ClusterRoleBinding.

This simply binds the `dotmesh` ServiceAccount to the `dotmesh`
ClusterRole. You shouldn't need to change this.

## The `dotmesh-operator` ClusterRoleBinding.

This simply binds the `dotmesh` ServiceAccount to the `cluster-admin`
ClusterRole (so that it can manage pods and PVCs). You shouldn't need
to change this.

## The `dotmesh` Service.

This is the service used to access the Dotmesh server on
port 32607. It's needed both for internal connectivity between nodes in
the cluster, and to allow other clusters to push/pull from this one.

## The `dotmesh-operator` Deployment.

This runs the Dotmesh operator, which then creates a Dotmesh server
pod for every node in your cluster (that matches the `nodeSelector` in
the ConfigMap, at any rate).

The operator references the `dotmesh-operator` ServiceAccount in order
to be able to create and destroy pods and PVCs.

The Dotmesh server pods it creates reference the `dotmesh`
ServiceAccount in order to obtain the privileges it needs.

They also refer to the `dotmesh` secret (also in the `dotmesh`
namespace) to configure the initial API key and admin password, which
is not created by the YAML - you have to provide these secrets
yourself; we wouldn't dream of shipping you a default API key! This
gets mounted into the container filesystem at `/secret`.

## The `dotmesh-provisioner` ServiceAccount.

This is the ServiceAccount that will be used to run the Dotmesh
provisioner. You shouldn't need to change this.

## The `dotmesh-provisioner-runner` ClusterRole.

This is the role the Dotmesh provisioner will run under. You shouldn't
need to change this.

## The `dotmesh-provisioner` ClusterRoleBinding.

This simply binds the `dotmesh-provisioner` ServiceAccount to the
`dotmesh-provisioner-runner` ClusterRole. You shouldn't need to change
this.

## The `dotmesh-dynamic-provisioner` Deployment.

This actually runs the dynamic provisioner. Only one replica of it
needs to run somewhere in the cluster; it just looks for Dotmesh PVCs
and creates corresponding PVs, so it doesn't need to actually run on
very node.

It references the `dotmesh` secret from the `dotmesh` namespace, in
order to obtain the cluster's admin API key so it can communicate with
the Dotmesh server.

## The `dotmesh` StorageClass.

This defines a default `dotmesh` StorageClass that, when referenced
from a PersistentVolumeClaim, will cause Dotmesh to manage the
resulting volume.

In the `parameters` section, there's a single configurable
item. `dotmeshNamespace` is the default namespace for dots accessed
through this StorageClass. You probably don't need to change it unless
you're doing something interesting.

## Dotmesh PersistentVolumeClaims.

A PersistentVolumeClaim using a Dotmesh StorageClass has the following structure:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: example-pvc
  annotations:
    dotmeshNamespace: admin
    dotmeshName: example
    dotmeshSubdot: logging_db
spec:
  storageClassName: dotmesh
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

The interesting parts:

 * `spec.storageClassName` must reference a suitably configured Dotmesh
   StorageClass, or Dotmesh won't manage this volume.
 * `metadata.annotations.dotmeshNamespace` can be used to override the
   namespace in which the dot is kept. The default is inherited from
   the StorageClass, or defaults to `admin` if none is specifed there,
   so it needn't be specified here unless you're doing something
   strange.
 * `metadata.annotations.dotmeshName` is the name of the dot. If you
   don't specify it, then the name of the PVC (in this case,
   `example-pvc`) will be used.
 * `metadata.annotations.dotmeshSubdot` is the name of the subdot to
   use. If left unspecified, then the default of `__default__` will be
   used. Use `__root__` to reference the root of the dot, or any other
   name to use a specific subdot.
