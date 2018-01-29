+++
draft = false
title = "Installing on Docker"
synopsis = "Installing Dotmesh on a computer with Docker installed"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "2"
[menu]
  [menu.main]
    parent = "install-setup"
+++

## Supported versions

* Docker >= 1.8.0

## Linux and macOS

Install the dotmesh client `dm` on macOS or Ubuntu Linux (TODO: add more distributions here when we support them).

{{< copyable name="step-1" >}}
sudo curl -sSL -o /usr/local/bin/dm \
    https://get.dotmesh.io/$(uname -s)/dm
{{< /copyable >}}  

Make the client binary executable.
```bash
sudo chmod +x /usr/local/bin/dm
```

Then use the client to install `dotmesh-server`, assuming you have Docker installed and your user account has access to the Docker daemon.

```bash
dm cluster init
```

```plain
Checking suitable Docker is installed... yes, got 17.12.0-ce.
Checking dotmesh isn't running... done.
Pulling dotmesh-server docker image...
[...]
```

This will set up a single-instance cluster on your local machine.

Verify that the `dm` client can talk to the `dotmesh-server`:
```bash
dm list
```

If the installation fails, please [report an issue](https://github.com/dotmesh-io/dotmesh).
You can also experiment with our [online learning environment](/install-setup/katacoda/).
Thanks!

## What's next?

Now that you've got `dm` installed on Docker, the Docker integration will work automatically.

Take it for a spin with the [Basic Docker demo](/tutorials/hello-dotmesh-docker/).

## Clustering

If you want your [Datadots](/concepts/what-is-a-datadot/) to be available automatically across multiple machines, you can join more nodes to the one-node cluster you just created using [`dm cluster join`](/references/cli/#join-a-cluster-dm-cluster-join-use-pool-dir-path-use-pool-name-zfs-pool-discovery-url).
You can also deploy [Dotmesh on Kubernetes](/install-setup/) with a DaemonSet so that it automatically gets installed on all the machines in your cluster.

* [Supported Docker versions](TODO)
* [Supported Linux Distributions](TODO)
* [Architecture](/concepts/architecture/)
* [Dotmesh on Kubernetes](/install-setup/)
