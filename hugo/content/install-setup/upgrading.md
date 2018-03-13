+++
draft = false
title = "Upgrading"
synopsis = "Instructions for upgrading your dotmesh cluster"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
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

Apply the latest stable dotmesh YAML for your Kubernetes version. For 1.6 and 1.7:

{{< copyable name="step-5" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.7.yaml
{{< /copyable >}}

For 1.8 and 1.9:

{{< copyable name="step-5" >}}
kubectl apply -f https://get.dotmesh.io/yaml/dotmesh-k8s-1.8.yaml
{{< /copyable >}}

You'll notice the version of `dotmesh-server` is specified in the image tags within the Kubernetes YAML.

Run:

{{< copyable name="step-6" >}}
dm version
{{< /copyable >}}

To check that the version of the client and the server match, and are up-to-date.
