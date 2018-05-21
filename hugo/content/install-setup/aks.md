+++
draft = false
title = "Install on AKS"
synopsis = "Installing Dotmesh on a AKS cluster"
knowledgelevel = ""
date = 2017-12-22T11:27:29Z
weight = "6"
[menu]
  [menu.main]
    parent = "install-setup"
+++

{{% overview %}}
* An account on the [Azure](https://azure.microsoft.com/en-us/free/)
* The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* `kubectl` installed via the Azure CLI, run `az aks install-cli`
* Enable the AKS preview via the [Azure CLI] (az provider register -n Microsoft.ContainerService)
{{% /overview %}}

This guide will show you how to install dotmesh onto a Kubernetes
cluster provisioned on [Azure Container Service](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough). We support
Kubernetes 1.8 on AKS clusters. AKS is currently in preview, for further updates please see the [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough).

## Authenticate

First - let's authenticate our `az` cli and point to the correct subscription.

Change the value of `mySubscription` with the subscription you wish to provision the AKS cluster in:

```plain
export AZ_SUBSCRIPTION_ID=<mySubscription>
```

Then we use the `az` cli to authenticate:

{{< copyable name="step-01" >}}
az login
az account set --subscription $AZ_SUBSCRIPTION_ID
{{< /copyable >}}

## Create a resource group

Create a resource group with the `az group create` command. An Azure resource group is a logical group in which Azure resources are deployed and managed. When creating a resource group you are asked to specify a location, this is where your resources will live in Azure. While AKS is in preview, only some location options are available. These are eastus, westeurope, centralus, canadacentral, canadaeast. See the [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough#create-a-resource-group) for further updates on location availability.


```plain
export AZ_RESOURCE_GROUP=<myResourceGroup>
export AZ_RESOURCE_GROUP_LOCATION=eastus
```

{{< copyable name="step-01" >}}
az group create --name $AZ_RESOURCE_GROUP --location $AZ_RESOURCE_GROUP_LOCATION
{{< /copyable >}}

## Provision cluster

Then we provision a new Kubernetes cluster of 3 nodes:

{{< copyable name="step-02" >}}
az aks create --resource-group $AZ_RESOURCE_GROUP --name myAKSCluster --node-count 3 --generate-ssh-keys --kubernetes-version 1.8.7
{{< /copyable >}}


## Create namespace & secrets

Before we can install Dotmesh, we need to set our admin password and api key:

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

Use the following command to apply the YAML configuration for running dotmesh:

{{< copyable name="step-06a" >}}
kubectl apply -f https://get.dotmesh.io/yaml/configmap.aks.yaml
{{< /copyable >}}

```plain
configmap "configuration" configured
```

{{< copyable name="step-06b" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.aks.yaml
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

**NOTE** - This will create a service of type Loadbalancer that will expose port port 32607 on the Internet. The need for a firewall rule will be replaced with an ingress rule in an upcoming release.

Let's check to see that we have our dotmesh server pods running on our Kubernetes cluster.  They might take a few moments to get going - wait for the pods to start before proceeding.

{{< copyable name="step-01" >}}
kubectl get po -n dotmesh
{{< /copyable >}}

```plain
NAME                                          READY     STATUS    RESTARTS   AGE
dotmesh-dynamic-provisioner-5599bfc5f-f5v8z   1/1       Running   0          9m
dotmesh-etcd-cluster-0000                     1/1       Running   0          10m
dotmesh-etcd-cluster-0001                     1/1       Running   0          10m
dotmesh-etcd-cluster-0002                     1/1       Running   0          10m
dotmesh-operator-7ff894567-mx75b              1/1       Running   0          1h
server-node1                                  1/1       Running   0          9m
server-node2                                  1/1       Running   0          9m
server-node3                                  1/1       Running   0          9m
etcd-operator-56b49b7ffd-rh5ql                1/1       Running   0          10m
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
export SERVICE_IP=$(kubectl get svc dotmesh --namespace dotmesh --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
dm remote add aks admin@$SERVICE_IP
{{< /copyable >}}

```plain
API key: Paste your API key here, it won't be echoed!

Remote added.
```

The `aks` part is just a name for this cluster that you'll use in
subsequent [dm remote
commands](/references/cli/#connecting-to-clusters), so pick something
that describes it.

You can then switch to that remote, and use it:


{{< copyable name="step-08" >}}
dm remote switch aks
dm list
{{< /copyable >}}

## What's next?

* [Hello Dotmesh on Kubernetes](/tutorials/hello-dotmesh-kubernetes/).
* [Adding dots to Kubernetes YAMLs](/tasks/kubernetes/).
* [Kubernetes YAML reference guide](/references/kubernetes/)
* [Command Line Reference](/references/cli/)
