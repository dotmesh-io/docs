+++
draft = false
title = "Command Line Reference"
synopsis = "Drive Dotmesh from your shell"
knowledgelevel = "Intermediate"
date = 2018-01-24T13:22:53Z
weight = "1"
[menu]
  [menu.main]
    parent = "references"
+++

Let's take a look at the `dm` command-line tool in more detail. This
is a reference guide - a [tutorial](../../tutorials) is where to go if
you want a quick start guide. We're also going to assume you're
familiar with [Dotmesh concepts](../../concepts/) here. As a reference, it's
written so you can dive straight into the heading for the command you
want - but it's also been laid out in a suitable order for reading
top-to-bottom, should you want to become a Dotmesh command-line expert
and impress your friends.

## How to read the examples.

In the examples given in this guide, anything in `CAPITALS` is
something you need to replace with your own text. For instance, if
you're told to type `dm commit -m 'MESSAGE'`, that means you need to
put your own message in instead of `MESSAGE`. Anything in `[square
brackets]` is optional; the text will describe the consequences of
missing it out. Lists of things `separated|by|vertical|pipes` indicate
that you get to choose one of them.

Examples look like this:

<div class="highlight"><pre class="chromaManual">
$ <kbd>cat hello.txt # Text YOU type looks like this</kbd>
Hello! Text the computer echoes back to you looks like this.

If any bits of the output need calling out, we'll highlight them
<em>like this</em>.
</pre></div>

## Basics.

If you just type `dm` on its own, it will give you basic command-line
help. `dm` uses the "subcommands" pattern, where one command provides
lots of different functions through different subcommands given on the
command line. For instance, `dm version` will print out the versions
of Dotmesh components. Some subcommands have subcommands of their own
(for instance, `dm dot delete` to delete a Dot).

You can get further information about any command by typing `dm
COMMAND --help`.

### `dm`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm</kbd>
dotmesh (dm) is like git for your data in Docker.

This is the client. Configure it to talk to a dotmesh cluster with 'dm remote
add'. Create a dotmesh cluster with 'dm cluster init'.

Usage:
  dm [command]

Available Commands:
  branch      List branches
  checkout    Switch or make branches
  clone       Make a complete copy of a remote dot
  cluster     Install a dotmesh server on a docker host, creating or joining a cluster
  commit      Record changes to a dot
  debug       Make API calls
  dot         Manage dots
  init        Create an empty dot
  list        Enumerate dots on the current remote
  log         Show commit logs
  pull        Pull new commits from a remote dot to a local copy of that dot
  push        Push new commits from the current dot and branch to a remote dot (creating it if necessary)
  remote      List remote clusters. Use dm remote -v to see remotes
  reset       Reset current HEAD to the specified state
  s3          Commands that handle S3 connections
  switch      Change which dot is active
  version     Show the Dotmesh version information

Flags:
  -c, --config string   Config file to use (default "~/.dotmesh/config")
      --verbose         Display details of RPC requests and responses to the dotmesh server

Use "dm [command] --help" for more information about a command.
</pre></div>

### `dm version --help`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm version --help</kbd>
Show the Dotmesh version information

Usage:
  dm version [flags]

Global Flags:
  -c, --config string   Config file to use (default "~/.dotmesh/config")
      --verbose         Display details of RPC requests and responses to the dotmesh server
</pre></div>

## The configuration file.

`dm` stores some local state in a config file. You never need to edit
this directory - `dm` will manage it for you. By default, it's located
in `$HOME/.dotmesh/config`, but all `dm` subcommands accept a `-c
PATH` or `--config PATH` flag, to make `dm` use a different config file.

## Verbose mode

You can view the contents of the RPC requests between the `dm` client and the
dotmesh server by using the `--verbose` flag.  It will print the contents of
the JSON request and reponse body to standard out.

## Connecting to clusters.

`dm` communicates to Dotmesh clusters using the [Dotmesh
API](../api/). In order to do anything interesting, it needs a
username, a hostname to connect to, and an API key to use. These login
details for a cluster are called a "remote", and a list of remotes is
stored in [the configuration file](#the-configuration-file).

One of the remotes in the config file is marked as the "current
remote". That's the one `dm` will use, until told otherwise.

If you create a local cluster using `dm cluster init`, then the
username will always be `admin`; the admin user is created by `dm
cluster init` and automatically saved under a remote called `local`
which is current to begin with, so `dm` commands will just work out
of the box. But if you need to connect to an existing cluster, or you
want to use the `dm` command directly against the Hub, you're going to
need to add a remote yourself.

The following commands are for managing the list of remotes stored in
your local configuration file.

### Add a new remote: `dm remote add NAME USER@HOSTNAME[:PORT]`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote add test alaric@test-cluster.local</kbd>
API key: <kbd>Paste your API key here, it won't be echoed!</kbd>

Remote added.

</pre></div>
You can optionally specify a port if your remote cluster is not running on the default port (`32607`).

You can get your Hub API key by browising to the [Settings/API
Key](https://saas.dotmesh.io/ui/settings/apikey) page on the Hub.

To get the admin API key for a Kubernetes Dotmesh cluster, get the
`dotmesh-api-key.txt` key from the `dotmesh` secret in the `dotmesh`
namespace:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl examine secret dotmesh -n dotmesh -o yaml</kbd>
apiVersion: v1
data:
  dotmesh-admin-password.txt: Y29ycmVjdGhvcnNlYmF0dGVyeXN0YXBsZQo=
  dotmesh-api-key.txt: <em>VlZLR1lDQzNHNEs1RzJRTTNHTElWVEVDVlNCV1dKWkQK</em>
kind: Secret
metadata:
  creationTimestamp: 2018-01-17T15:03:11Z
  name: dotmesh
  namespace: dotmesh
  resourceVersion: "418"
  selfLink: /api/v1/namespaces/dotmesh/secrets/dotmesh
  uid: 88c31d8b-fb97-11e7-b1fe-0242cd52be10
type: Opaque
$ <kbd>echo VlZLR1lDQzNHNEs1RzJRTTNHTElWVEVDVlNCV1dKWkQK | base64 -d</kbd>
<em>VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD</em>
</pre></div>

The admin API key from an existing Docker-based cluster created with
`dm cluster init` can be found from the Dotmesh config file where `dm
cluster init` was run, with the following command:

<div class="highlight"><pre class="chromaManual">
$ <kbd>cat ~/.dotmesh/config | jq -r .Remotes.local.ApiKey</kbd>
<em>VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD</em>
</pre></div>

For S3 remotes please see [`dm s3 remote add`](#add-a-new-s3-remote-dm-s3-remote-add-access-key-secret-key-host-port)
### List remotes: `dm remote -v`

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote -v</kbd>
  hub	alaric@dothub.com
  test  alaric@test-cluster.local
<em>* local	admin@127.0.0.1</em>
</pre></div>

All the remotes in the config file are listed, one per line. Each line
has the name of the remote, followed by the username and the hostname
in `USER@HOSTNAME` form. The API keys are not printed out.

Note that the current remote is marked with a `*` at the start of the
line.

### Remove a remote: `dm remote rm NAME`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote -v</kbd>
  hub	alaric@dothub.com
  test  alaric@test-cluster.local
* local	admin@127.0.0.1
$ <kbd>dm remote rm test</kbd>
$ <kbd>dm remote -v</kbd>
  hub	alaric@dothub.com
* local	admin@127.0.0.1
</pre></div>

### Select the current remote: `dm remote switch NAME`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote -v</kbd>
  hub	alaric@dothub.com
<em>* local</em>	admin@127.0.0.1
$ <kbd>dm remote switch hub</kbd>
$ <kbd>dm remote -v</kbd>
<em>* hub</em>	alaric@dothub.com
  local	admin@127.0.0.1
</pre></div>

### Comparing client and remote versions: `dm version`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm version</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

Client:
	Version: release-0.1.0
Server:
	Version: release-0.1.0
</pre></div>

## Dot management.

### The current dot.

You often need to perform lots of operations on a single dot, so
rather than specifying the name of the dot in every command, each
remote in the config file has a "current dot". That means that if you
switch remotes, the current dot will change, and will change back if
you return to the original remote. The current dot for each remote is
stored in [the configuration file](#the-configuration-file).

### List the available dots: `dm list [-H|--scripting]`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm list</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT             BRANCH  SERVER            CONTAINERS  SIZE       COMMITS  DIRTY
<em>* important_data  master  504954d09db78174              19.00 kiB  0        19.00 kiB</em>
  test_data       master  504954d09db78174              19.00 kiB  0        19.00 kiB
</pre></div>

Note that the current dot is marked with a `*` at the start of the line. The fields are:

 * The dot name.
 * The currently selected branch on that dot.
 * The ID of the server that's currently managing that dot.
 * The names of any containers currently using this dot.
 * The size of the dot.
 * How many commits have been made on this branch of the dot.
 * How much data has been generated or modified since the last commit.

If you're writing a script, you can also obtain this information in a more parseable format (without headings or prettification of numbers, and with a single tab between each field) using `dm list -H` or `dm list --scripting` - but it might be easier to [use the API](../api/#dotmeshrpc-list) if you're doing anything more complicated.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm list -H</kbd>
important_data	master	504954d09db78174		19456	0	19456
test_data	master	504954d09db78174		19456	0	19456
</pre></div>

### Select a different current dot: `dm switch DOT`.

Remember, each remote has a different list of dots - so the current
dot is particular to each remote.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm list</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT             BRANCH  SERVER            CONTAINERS  SIZE       COMMITS  DIRTY
<em>* important_data</em>  master  504954d09db78174              19.00 kiB  0        19.00 kiB
  test_data       master  504954d09db78174              19.00 kiB  0        19.00 kiB
$ <kbd>dm switch test_data</kbd>
$ <kbd>dm list</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT             BRANCH  SERVER            CONTAINERS  SIZE       COMMITS  DIRTY
  important_data  master  504954d09db78174              19.00 kiB  0        19.00 kiB
<em>* test_data</em>       master  504954d09db78174              19.00 kiB  0        19.00 kiB
</pre></div>

### Create an empty dot: `dm init DOT`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm init staging_data</kbd>
$ <kbd>dm list</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT             BRANCH  SERVER            CONTAINERS  SIZE       COMMITS  DIRTY
  important_data  master  504954d09db78174              19.00 kiB  0        19.00 kiB  
<em>* staging_data    master  504954d09db78174              19.00 kiB  0        19.00 kiB</em>
  test_data       master  504954d09db78174              19.00 kiB  0        19.00 kiB  
</pre></div>

A newly created dot has no subdots, but it starts off with a small
amount of "dirty" data because basic filesystem metadata has been
created.

### Delete a dot: `dm dot delete [-f|--force] DOT`.

You will be prompted for confirmation, unless you specify the `-f` or `--force` flag.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm dot delete staging_data</kbd>
Please confirm that you really want to delete the dot staging_data, including all
branches and commits? (enter Y to continue): <kbd>Y</kbd>
</pre></div>

### Examine a dot: `dm dot show [-H|--scripting] DOT`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm dot show test_data</kbd>
Dot admin/test_data:
Master branch ID: e05cf6bf-46b9-4e34-6e08-01bc9f323a72
Dot is current.
Dot size: 19.00 kiB (19.00 kiB dirty)
Branches:
* master
Tracks dot alaric/test_data on remote hub
</pre></div>

The results show:

 * The full name of the dot, including a namespace.
 * The master branch ID, which isn't something you generally need when using the command line, but is useful for debugging your API apps.
 * If this dot is the current dot, it will display `Dot is current.`
 * The size of the dot, and the amount of generated/modified "dirty" data since the last snapshot.
 * The list of all the branches of the dot, with the current branch marked with a `*`.
 * The [default upstream dot](#transferring-dots) on each remote that has one configured for this dot.

You can get all that data in a form more amenable to scripting with the `-H` or `--scripting` option:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm dot show --scripting test_data</kbd>
namespace	admin
name	test_data
masterBranchId	e05cf6bf-46b9-4e34-6e08-01bc9f323a72
current
size	19456
dirty	19456
currentBranch	master
branch	master
defaultUpstreamDot	hub	alaric/test_data
</pre></div>

## Transferring dots.

When you clone a dot from the Hub or another cluster, `dm` stores the
assocation between your local dot and the original remote dot in [the
configuration file](#the-configuration-file).

Likewise, if you push a dot to another cluster, or pull updates to it
from another cluster, `dm` will remember that association if it didn't
already have one for that remote.

Each dot may have a "default upstream dot" for each remote in your
configuration. There can't be two default upstreams of a dot on any
remote, but there might be none!

The list of upstream dots for a dot can be viewed with `dm dot show
DOT`. Upstream dots may be assigned or re-assigned with `dm dot
set-upstream [DOT] REMOTE REMOTE-DOT`.

These commands can be a little confusing, because they involve two
remotes at once. There is always a current remote selected with `dm
remote switch` that is the "target" of your commands; that's the
"local cluster" from the perspective of these commands. The command
line for transfer commands always names a second remote, which is the
"remote cluster" we are transferring dots to and from.

### Clone: `dm clone [--local-name LOCAL-DOT] REMOTE DOT BRANCH`

In this example, we'll clone the dot `alice/testing_data` from the
Hub, and call it `new_data` locally.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm clone --local-name new_data hub alice/testing_data</kbd>
Pulling admin/new_data from hub:alice/testing_data
Calculating...
finished 9.50 KB / 9.50 KB [==========================] 100.00% 0.43 MiB/s (1/1)
Done!
</pre></div>

If we run `dm dot show` on `new_data`, we'll see that
`alice/testing_data` is the default upstream dot for it on `hub`:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm dot show new_data</kbd>
Dot admin/new_data:
Master branch ID: c78bb46e-0d52-43e9-70bc-f2b78ace0f9d
Dot size: 19.00 kiB (all clean)
Branches:
* master
<em>Tracks dot alice/test_data on remote hub</em>
</div>

If you omit the `--local-name LOCAL-DOT` part, then the dot will just
have the same name as the remote one - in this case, `testing_data`.

If you are cloning an S3 bucket and only want to select a subset of the files, please see [`dm s3 clone-subset`](#clone-a-section-of-an-s3-bucket-dm-s3-clone-subset-remote-bucket-prefixes-local-name-local-dot)

### Pull: `dm pull REMOTE [DOT [BRANCH]] [--remote-name REMOTE-DOT]`

This command pulls new commits and branches from a remote dot into
your local cluster.

If you only specify a `REMOTE` name, then it will attempt to pull
updates to all branches of the current dot from that remote. If you
have specified `--remote-name REMOTE-DOT`, it will pull from
`REMOTE-DOT` on the remote cluster. If not, and there is a default
upstream dot for that remote, it will pull from that dot. Otherwise,
it will pull from a dot with the same name as the current dot on your
local cluster, in the namespace corresponding to your username on the
remote cluster (eg, your Hub username).

If you specify a `REMOTE` name and a `DOT` name, then it will perform
the same steps, but with the local dot being the one named rather than
the current dot.

If you specify a `REMOTE` name, a `DOT` name and a `BRANCH`, then it
will only pull new commits on the named branch, rather than trying to
pull commits for every branch.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm pull hub</kbd>
Pulling admin/new_data from hub:alice/testing_data
Calculating...
finished 9.50 KB / 9.50 KB [==========================] 100.00% 0.43 MiB/s (1/1)
Done!
</pre></div>

### Push: `dm push REMOTE [--remote-name DOT]`

This command pushes the current branch of the current dot to the
specified `REMOTE`. If the destination dot already exists, local
commits that aren't present in the destination will be pushed up,
bringing it up to date. If the destination does not already exists, it
will be created and all the commits on the current branch (and other
branches that the current branch depends upon) will be pushed up.

If `--remote-name` is specified, then that is the name of the
destination dot on the remote cluster. Otherwise, if the current dot
has a default upstream dot for that remote, that will be the
destination dot. If not, the destination dot name will be the same as
the current dot's name, but in your user's namespace on the remote.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm push hub</kbd>
Pushing admin/new_data to hub:alice/testing_data
Calculating...
finished 9.50 KB / 9.50 KB [==========================] 100.00% 0.38 MiB/s (1/1)
Done!
</pre></div>

### Set the upstream dot: `dm dot set-upstream [DOT] REMOTE REMOTE-DOT`

You can set the upstream dot for any given remote using this
command. If you omit the `DOT`, then the current dot is used.

<div class="highlight"><pre class="chromaManual">
$ dm dot set-upstream new_data production bob/test_data
$ <kbd>dm dot show new_data</kbd>
Dot admin/new_data:
Master branch ID: c78bb46e-0d52-43e9-70bc-f2b78ace0f9d
Dot size: 19.00 kiB (all clean)
Branches:
* master
Tracks dot alice/test_data on remote hub
<em>Tracks dot bob/test_data on remote production</em>
</div>

## Using dots.

These commands deal with the contents of a dot: branches and commits.

### Commit: `dm commit -m 'MESSAGE' [--metadata fieldname=value]`.

This command takes the "dirty" changes to the current dot since the
last commit (or the creation of the dot), and makes them into a new
commit with the given `MESSAGE`.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm commit -m "A well-written commit message"</kbd>
</pre></div>

You can also pass extra metadata fields that are added to the commit
by using the `--metadata` flag.  You can pass multiple metadata fields,
each using the format: `--metadata fieldname=value`:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm commit -m "A well-written commit message" --metadata fruit=apples --metadata color=red</kbd>
</pre></div>

### List commits: `dm log`.

This command lists the commits on the current branch.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm log</kbd>
commit <em>c96eefda-6940-499a-411c-22521f4a3452</em>
author: admin
date: 1516898188388491967
fruit: apples
color: red

    A well-written commit message

commit <em>e568407c-5ea3-42bc-48e8-6e375c121d2b</em>
author: admin
date: 1516898511693726664
fruit: apples
color: red

    A poorly-written commit message


</pre></div>

Note the commit IDs (highlighted) - they are needed to do a `dm reset`.

### List the branches: `dm branch`.

This command lists the branches in the current dot.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm branch</kbd>
  version_1
<em>* master</em>
</pre></div>

Note how the current branch is indicated with a leading `*`.

### Create a branch: `dm checkout -b BRANCH`.

This command creates a new branch, starting with the current branch,
and makes the new branch current.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm checkout -b version_2</kbd>
</pre></div>

### Switch branches: `dm checkout BRANCH`.

This command makes a different branch current. If there are running
containers using this dot that haven't been pinned to a specific
branch, they will be stopped before the change and restarted
afterwards, using the new branch.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm checkout version_1</kbd>
</pre></div>

### Roll back commits: `dm reset [--hard] COMMIT`.

This command rolls back the state of the current branch to a given
commit ID (which must be from this branch!). To get the commit IDs,
use `dm log`.

The command won't let you roll back if there are uncommitted changes,
unless you specify `--hard` to override it.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm reset c96eefda-6940-499a-411c-22521f4a3452</kbd>
</pre></div>

## Cluster management.

These commands are for managing a Dotmesh cluster built using
Docker. If you're using Kubernetes, you don't need these commands -
the Dotmesh Kubernetes integration handles all of this for you!

### Create a cluster: `dm cluster init [--port PORTNUM]`.

This command creates a new single-node Dotmesh cluster. You can force the cluster to be exposed on a specific port by specifying the port flag.

If a ZFS pool called `pool` already exists, it will be used for Dot
storage. Otherwise, Dotmesh will default to creating a pool based on a
file in `/var/lib/dotmesh`. The file will be ten gigibytes in size.

The newly-created cluster will be automically configured as a remote
called `local` in your `dm` [configuration
file](#the-configuration-file).

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm cluster init</kbd>
Checking suitable Docker is installed... assuming post-semver Docker client is sufficient.
assuming post-semver Docker server is sufficient.
Checking dotmesh isn't running... done.
Pulling dotmesh-server docker image... done.
Registering new cluster... got URL:
https://discovery.dotmesh.io/da045bfb125bb69f7f55902ed0409494
Generating PKI assets... done.
If you want more than one node in your cluster, run this on other nodes:

    <em>dm cluster join https://discovery.dotmesh.io/da045bfb125bb69f7f55902ed0409494:DYJNVRS2PNJVBTQ44P3KVAC7LWKV325X</em>

This is the last time this secret will be printed, so keep it safe!

Guessing docker host's IPv4 address (should be routable from other cluster nodes)... got: 192.168.1.34,192.168.1.33,10.192.0.1,172.18.0.1,172.19.0.1.
Guessing unique name for docker host (using hostname, must be unique wrt other cluster nodes)... got: nixos.
Starting etcd... done.
Succeeded setting initial admin password to 'UMY5XI6WFMHKAMNO2HGWGN3MHQ74KMUH' - writing it to /home/alaric/.dotmesh/admin-password.txt
Configuring dm CLI to authenticate to dotmesh server /home/alaric/.dotmesh/config... done.
Starting dotmesh server... done.
Waiting for dotmesh server to come up...
done.
</pre></div>

Note the join command, highlighted in the example above. Keep a copy
of that - you can't get it again, and you'll need it if you want to
add any more nodes to your cluster.

### Join a cluster: `dm cluster join DISCOVERY-URL`.

This command sets up a Dotmesh node on your computer, and joins it
into an existing cluster using the `DISCOVERY-URL` printed out when
the original cluster was created.

If you specify a pool `PATH`, then files will be created in the
directory pointed at by `PATH` to store the actual dots.

If, instead, you specify a `ZFSPOOL`, then the dots will be stored in
the ZFS pool with that name, which you must have created yourself. Use
this option if you have dedicated disk partitions for Dotmesh to
use.

If you specify neither, then Dotmesh will default to creating a pool
directory in `/var/lib/dotmesh`.

The cluster will be automically configured as a remote called `local`
in your `dm` [configuration file](#the-configuration-file).

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm cluster join https://discovery.dotmesh.io/1e52c023dfaa2f9e812ec7835bdd0540:OWSWZGRMUCBT5FFFD5NJIVCP5QQSQXVH</kbd>
Checking suitable Docker is installed... yes, got 1.12.6.
Checking dotmesh isn't running... done.
Pulling dotmesh-server docker image... done.
Downloading PKI assets... done!
Guessing docker host's IPv4 address (should be routable from other cluster nodes)... got: 10.192.0.2.
Guessing unique name for docker host (using hostname, must be unique wrt other cluster nodes)... got: cluster-1516891762883170057-0-node-0.
Starting etcd... done.
Succeeded getting initial admin API key 'E3M6NJBGEEIWEKSPH7E4XLQAKQBQPBAB'
Configuring dm CLI to authenticate to dotmesh server /root/.dotmesh/config... done.
Starting dotmesh server... done.
Waiting for dotmesh server to come up....
done.
</pre></div>

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

### Remove Dotmesh from your node: `dm cluster reset`.

This command stops the Dotmesh server on the current node, then
deletes its resources. It doesn't delete the Dot data itself, but it
does destroy the local copy of the Dot metadata!

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm cluster reset</kbd>
Destroying all dotmesh data... done.
Deleting dotmesh-etcd container... done.
Deleting dotmesh-server containers... done.
Deleting dotmesh-server-inner containers... done.
Deleting dotmesh socket... done.
Deleting dotmesh-etcd-data local volume... done.
Deleting dotmesh-kernel-modules local volume... done.
Deleting 'local' remote... done.
Deleting cached PKI assets... done.
</pre></div>

## S3 management.
### Add a new S3 remote: `dm s3 remote add ACCESS_KEY:SECRET_KEY[@HOST:PORT]`.
<div class="highlight"><pre class="chromaManual">
$ <kbd>dm s3 remote add test access_key:secret</kbd>

S3 remote added.

</pre></div>

Invoking this command will check that Dotmesh is able to list buckets using the access key and secret supplied - if it cannot connect it will fail with an appropriate error.

You can then manage S3 buckets using `clone`, `push` and `pull` as if they were Dotmesh servers, but you will not be able to make an S3 remote your current default. You can also clone a subset of an S3 bucket using `dm s3 clone-subset`.

It is recommended that you enable versioning on your S3 bucket in order for Dotmesh to be able to discern changes easily.

The access key-secret pair you use will need the following actions to be allowed on AWS S3 in order to work effectively:
 * s3:PutObject
 * s3:DeleteObject
 * s3:HeadBucket
 * s3:GetBucketLocation
 * s3:GetObject
 * s3:GetObjectVersion
 * s3:ListBucketVersions

### Clone a section of an S3 bucket: `dm s3 clone-subset REMOTE BUCKET PREFIXES [--local-name LOCAL-DOT]`.
This command will clone only a selection of files from an S3 bucket, as dictated by PREFIXES.

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm s3 clone-subset --local-name new_data s3 test directory_1/</kbd>
Pulling admin/new_data from s3:/test
Calculating...
finished 9.50 KB / 9.50 KB [==========================] 100.00% 0.43 MiB/s (1/1)
Done!
</pre></div>

You can also use multiple prefixes, separating them by a comma:
<div class="highlight"><pre class="chromaManual">
$ <kbd>dm s3 clone-subset --local-name new_data s3 test directory_1/,hello-</kbd>
Pulling admin/new_data from s3:/test
Calculating...
finished 9.50 KB / 9.50 KB [==========================] 100.00% 0.43 MiB/s (2/2)
Done!
</pre></div>

When pulling or pushing a volume cloned in this way, only files which begin with these prefixes will be updated.