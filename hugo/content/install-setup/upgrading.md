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

### Upgrade your node: `dm cluster upgrade`.

This command stops the Dotmesh server on the current node, downloads
the Dotmesh server Docker image corresponding to the version of the
`dm` client you're using, and starts it up. You would normally upgrade
Dotmesh on your node by downloading a new `dm` client binary and
running `dm cluster upgrade` with it. You can use `dm version` to
check the client and server versions (make sure you've selected the
`local` remote!).

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm cluster upgrade</kbd>
Pulling dotmesh-server docker image... done.
Stopping dotmesh-server...done.
Stopping dotmesh-server-inner...done.
Starting dotmesh server... done.
</pre></div>


