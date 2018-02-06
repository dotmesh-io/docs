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

<div class="highlight"><pre class="chromaManual">
$ <kbd>gcloud auth login</kbd>
$ <kbd>gcloud config set project my-gcloud-project</kbd>
Updated property [core/project].
</pre></div>

### Provision cluster

Then we provision a new Kubernetes cluster of 3 nodes:

<div class="highlight"><pre class="chromaManual">
$ <kbd>gcloud container clusters create dotmesh-gke-cluster \
    --image-type=ubuntu \
    --tags=dotmesh \
    --cluster-version=1.8.6-gke.0</kbd>
Creating cluster dotmesh-gke-cluster...done
</pre></div>

**NOTE** - At present the cluster needs to use `--image-type=ubuntu` - in upcoming releases this requirement will be removed.

Open port `6969` so external `dm` clients can communicate with our cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>gcloud compute firewall-rules create dotmesh-ingress \
  --allow tcp:6969 \
  --target-tags=dotmesh</kbd>
Creating firewall...done
</pre></div>

**NOTE** - The need for a firewall rule will be replaced with an ingress rule in an upcoming release

Check we have 3 nodes:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl get no -o wide</kbd>
NAME                                                ...  VERSION        EXTERNAL-IP      OS-IMAGE            ...
gke-dotmesh-gke-cluster-default-pool-3144fa14-bm45  ...  v1.8.6-gke.0   35.189.124.88    Ubuntu 16.04.3 LTS  ...
gke-dotmesh-gke-cluster-default-pool-3144fa14-ggl9  ...  v1.8.6-gke.0   35.189.104.196   Ubuntu 16.04.3 LTS  ...
gke-dotmesh-gke-cluster-default-pool-3144fa14-tdhw  ...  v1.8.6-gke.0   35.197.226.3     Ubuntu 16.04.3 LTS  ...
</pre></div>

## Cluster Admin Role

We need to ensure that we are known to the Kubernetes cluster as an administrator - to do this, we create a `cluster-admin` binding for our user:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user "$(gcloud config get-value core/account)"</kbd>
clusterrolebinding "cluster-admin-binding" created
</pre></div>

## Create namespace & secrets

Create the namespace and set the admin password and api key for your dotmesh cluster:

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

## Etcd operator

Install the etcd operator ready for our dotmesh cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-clusterrole.yaml</kbd>
clusterrolebinding "dotmesh-etcd-operator" configured
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/etcd-operator-dep.yaml</kbd>
deployment "etcd-operator" configured
</pre></div>

## Dotmesh

Use the following command to apply the YAML configuration for running dotmesh:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml</kbd>
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

<div class="highlight"><pre class="chromaManual">
$ <kbd>export NODE_IP=$(kubectl get no -o wide | tail -n 1 | awk '{print $6}')</kbd>
$ <kbd>dm remote add gke admin@$NODE_IP</kbd>
API key: <kbd>Paste your API key here, it won't be echoed!</kbd>

Remote added.
</pre></div>

The `gke` part is just a name for this cluster that you'll use in
subsequent [dm remote
commands](/references/cli/#connecting-to-clusters), so pick something
that describes it.

You can then switch to that remote, and use it:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote switch gke</kbd>
$ <kbd>dm list</kbd>
...
</pre></div>

## What's next?

* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
* [Kubernetes YAML reference guide](/references/kubernetes/)
* [Command Line Reference](/references/cli/)
