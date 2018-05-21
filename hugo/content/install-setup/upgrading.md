+++
draft = false
title = "Upgrading"
synopsis = "Instructions for upgrading your dotmesh cluster"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "7"
[menu]
  [menu.main]
    parent = "install-setup"
+++

## Upgrading Dotmesh on Docker

Download the latest stable `dm` client binary:

{{< copyable name="step-1" >}}
sudo curl -sSL -o /usr/local/bin/dm \
    https://get.dotmesh.io/$(uname -s)/dm
{{< /copyable >}}

Run:

{{< copyable name="step-2" >}}
dm cluster upgrade
{{< /copyable >}}

This will download the `dotmesh-server` docker image corresponding to the version of the `dm` client you're using.
It will then stop the Dotmesh server on the current node, and start the new version.

Run:

{{< copyable name="step-3" >}}
dm version
{{< /copyable >}}

To check that the version of the client and the server match, and are up-to-date.

## Upgrading Dotmesh on Kubernetes

Download the latest stable `dm` client binary:

{{< copyable name="step-4" >}}
sudo curl -sSL -o /usr/local/bin/dm \
    https://get.dotmesh.io/$(uname -s)/dm
{{< /copyable >}}

Apply the latest stable dotmesh YAML for your Kubernetes version. For 1.7 generic:

{{< copyable name="step-5" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.yaml
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml
{{< /copyable >}}

For 1.7 on GKE:

{{< copyable name="step-5a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.gke.yaml
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml
{{< /copyable >}}

For 1.8 or 1.9 generic:

{{< copyable name="step-5b" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.yaml
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

For 1.8 or 1.9 on GKE:

{{< copyable name="step-5c" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.gke.yaml
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

For 1.8 on AKS:

{{< copyable name="step-5d" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.aks.yaml
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.aks.yaml
{{< /copyable >}}

You'll notice the version of `dotmesh-server` is specified in the image tags within the Kubernetes YAML.

Run:

{{< copyable name="step-6" >}}
dm version
{{< /copyable >}}

To check that the version of the client and the server match, and are up-to-date.

## dotmesh 0.4 -> 0.5

In versions 0.4 and below, Dotmesh was deployed via a DaemonSet, but
version 0.5 introduces the Dotmesh Operator. Before upgrading to 0.5,
please manually delete the Dotmesh DameonSet before running the normal
upgrade procedure:

{{< copyable name="step-0.4-0.5-upgrade1" >}}
kubectl delete deployment dotmesh -n dotmesh
{{< /copyable >}}

## dotmesh 0.3 -> 0.4

In the dotmesh 0.4 release, we upgraded the version of the etcd operator (0.5.0 -> 0.8.4) and etcd (3.1.8 -> 3.2.13).
In order to be able to safely upgrade etcd and the etcd operator we added `dm cluster backup-etcd` and `dm cluster restore-etcd` commands.
These commands let you tolerate the loss of an etcd cluster during an etcd upgrade.

It may also be useful to automate running the `backup-etcd` command regularly, so that you can recover from etcd data loss due to, for example, upgrading your GKE cluster or rebooting your nodes all at the same time -- scenarios that the etcd operator deals with poorly.
Future versions of dotmesh will [automate continuous etcd backups](https://github.com/dotmesh-io/dotmesh/issues/359).

So to upgrade dotmesh and the etcd operator and etcd on Kubernetes, follow these steps:

* Download the latest stable `dm` client binary (see [here](#upgrading-dotmesh-on-kubernetes)).

* Apply the appropriate dotmesh YAML for your Kubernetes type (see [here](#upgrading-dotmesh-on-kubernetes)).

* You will now have a `dm` client and a running cluster which supports `backup-etcd` and `restore-etcd` commands.

* Back up etcd (assuming your `dm` binary is pointing at the right cluster, use `dm remote -v` to check):

{{< copyable name="step-0.3-0.4-upgrade0" >}}
dm cluster backup-etcd > dotmesh-etcd-backup.json
{{< /copyable >}}

* Now, deploy the latest etcd operator:

{{< copyable name="step-0.3-0.4-upgrade1" >}}
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml
kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml
{{< /copyable >}}

* Delete your etcd cluster, it may well be in a failed state anyway (`kubectl describe etcd dotmesh-etcd -n dotmesh` if you are curious), and besides, we need to kick it to upgrade the etcd version itself:

{{< copyable name="step-0.3-0.4-upgrade2" >}}
kubectl delete etcd dotmesh-etcd-cluster -n dotmesh
{{< /copyable >}}

* Create a new etcd cluster:

{{< copyable name="step-0.3-0.4-upgrade3" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-etcd-cluster.yaml
{{< /copyable >}}

* Wait for the etcd cluster to come back up (look for three `dotmesh-etcd-cluster-*` pods to come up):

{{< copyable name="step-0.3-0.4-upgrade4" >}}
kubectl get pods -n dotmesh
{{< /copyable >}}

* Restore the backup.

{{< copyable name="step-0.3-0.4-upgrade5" >}}
dm cluster restore-etcd < dotmesh-etcd-backup.json
{{< /copyable >}}
