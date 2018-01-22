+++
draft = false
title = "Installing on Docker"
synopsis = "Installing Dotmesh on a computer with Docker installed"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "install-setup"
+++

## Linux and macOS

Install the dotmesh client `dm` on macOS or Ubuntu Linux (TODO: add more distributions here when we support them).

```bash
sudo curl -sSL -o /usr/local/bin/dm \
    https://get.dotmesh.io/$(uname -s)/dm
```

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
Thanks!

## What's next?

Now that you've got `dm` installed on Docker, the Docker integration will work automatically.

Take it for a spin with the [Basic Docker demo](/tutorials/basic-docker/) (TODO: ensure link works).

## Clustering

If you want your [Datadots](/concepts/what-is/) to be available automatically across multiple machines, you can join more nodes to the one-node cluster you just created using [`dm cluster join`](/references/cli/#join) (TODO: ensure link works).

You can also deploy [Dotmesh on Kubernetes](TODO) with a DaemonSet so that it automatically gets installed on all the machines in your cluster.

## See also

* [Supported Docker versions](TODO)
* [Supported Linux Distributions](TODO)
* [Operations Guide](TODO)
