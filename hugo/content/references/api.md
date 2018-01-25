+++
draft = false
title = "API Reference"
synopsis = "Take control of Dotmesh"
knowledgelevel = ""
date = 2018-01-17T12:04:35Z
order = "2"
[menu]
  [menu.main]
    parent = "references"
+++

Internally, Dotmesh runs as a server on every node in a Dotmesh cluster.
Any interaction with Dotmesh, such as using the `dm` command-line tool, or running containers using Dotmesh volumes from Docker or Kubernetes, involves making API calls to the Dotmesh server on the affected node.

Most operations can be performed on any node in the cluster, and will automatically be routed to the node that is currently controlling any affected dot.
The only exceptions are API calls that mount a volume from a dot, which will cause that mount to happen on the node that receives the API call.
You need to ensure that you choose the most appropriate node to mount the volume on!

## Basics.

Every node in a Dotmesh cluster exposes the Dotmesh API on port 6969; in a Kubernetes cluster, this is made accessible as a ClusterIP service called "dotmesh" in the "dotmesh" namespace by default, which can be accessed through [the standard Kubernetes service discovery methods](https://kubernetes.io/docs/concepts/services-networking/service/#discovering-services).

Our API uses [JSON-RPC](http://www.jsonrpc.org) v2 over HTTP when
talking to a local cluster, or HTTPS for talking to the Hub. But don't
worry if you're not familiar with JSON-RPC - we'll explain everything
with examples below.

### Connecting to your Dotmesh cluster.

All API methods are invoked by making a POST to
`http://SERVERNAME:6969/rpc`, with Basic HTTP authentication. To talk
to your local cluster, you'll need the `admin` user and the
corresponding API key.  If you created your cluster from the command
line with `dm cluster init`, these can be found in the
`$HOME/.dotmesh/config` file:

<div class="highlight"><pre class="chromaManual">
$ <kbd>cat ~/.dotmesh/config | jq .Remotes.local.ApiKey</kbd>
"<em>VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD</em>"
</pre></div>

If your cluster was created purely through Kubernetes, the admin API
key can be found in the `dotmesh-api-key.txt` key in the `dotmesh`
secret, in the `dotmesh` namespace:

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

Requests must be sent with a `Content-Type` of `application/json`, and comply with the [JSON-RPC v2 specifiation](http://www.jsonrpc.org/specification), like so:

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Ping",
  "params": {},
  "id": 6129484611666146000
}
```

The response will come back in the JSON-RPC v2 response format:

```json
{
  "jsonrpc": "2.0",
  "result": "true",
  "id": 6129484611666146000
}
```

If there is a problem with your request, you will receive a standard JSON-RPC v2 error, like this:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32000,
    "message": "rpc: can't find method \"DotmeshRPC.AllYourBaseAreBelongToUs\"",
    "data": null
  },
  "id": 6129484611666146000
}
```

### Connecting to the Hub.

The same API that you use to control your local Dotmesh cluster is
used to talk to the Dotmesh Hub. However, some API methods are only
useful with the Hub, and some are only useful with a local cluster.

When connecting to the Hub, you'll need to know the user's Hub
username and their API key. They can get their API key by browsing to
the (FIXME: Where is the page to get your API key?) page.

The URL to send the JSON-RPC POSTs to is `https://saas.dotmesh.io:6969/rpc`.

FIXME: Check this URL is correct.

It's also possible to authenticate to the API by submitting a user's
password instead of their API key.

The password is intended for use when users log into administrative
interfaces and supply their username and password through a login
screen, rather than being stored; API keys are intended to be stored,
and can be easily revoked by the user, so most uses of the API should
use an API key instead. See the description of the [`GetApiKey`
method](#dotmeshrpc-getapikey) for information on this use case.

The one exception is API methods to manage the user account, which are
explicitly prohibited from use with just an API key, so that a lost
API key is not able to permanently compromise an account. These will
be called out as such in the documentation for those API methods.

## API reference.

The dotmesh API contains a whole load of different methods, so let's look at them in related groups. We'll start with the simplest!

 * Information
   * [DotmeshRPC.Ping](#dotmeshrpc-ping)
   * [DotmeshRPC.CurrentUser](#dotmeshrpc-currentuser)
   * [DotmeshRPC.Version](#dotmeshrpc-version)
 * User Account Control
   * [DotmeshRPC.GetApiKey](#dotmeshrpc-getapikey)
   * [DotmeshRPC.ResetApiKey](#dotmeshrpc-resetapikey)
   * [DotmeshRPC.AddCollaborator](#dotmeshrpc-addcollaborator)
 * Dot Management
   * [DotmeshRPC.Lookup](#dotmeshrpc-lookup)
   * [DotmeshRPC.Exists](#dotmeshrpc-exists)
   * [DotmeshRPC.Get](#dotmeshrpc-get)
   * [DotmeshRPC.List](#dotmeshrpc-list)
   * [DotmeshRPC.AllDotsAndBranches](#dotmeshrpc-alldotsandbranches)
   * [DotmeshRPC.Create](#dotmeshrpc-create)
   * [DotmeshRPC.ContainersById](#dotmeshrpc-containersbyid)
   * [DotmeshRPC.Containers](#dotmeshrpc-containers)
   * [DotmeshRPC.CommitsById](#dotmeshrpc-commitsbyid)
   * [DotmeshRPC.Commits](#dotmeshrpc-commits)
   * [DotmeshRPC.Commit](#dotmeshrpc-commit)
   * [DotmeshRPC.Rollback](#dotmeshrpc-rollback)
   * [DotmeshRPC.Branches](#dotmeshrpc-branchs)
   * [DotmeshRPC.Branch](#dotmeshrpc-branch)
   * [DotmeshRPC.Delete](#dotmeshrpc-delete)
 * Attachment
   * [DotmeshRPC.Procure](#dotmeshrpc-procure)
   * [DotmeshRPC.SwitchContainers](#dotmeshrpc-switchcontainers)
 * Transfers
    * [DotmeshRPC.Transfer](#dotmeshrpc-transfer)
    * [DotmeshRPC.GetTransfer](#dotmeshrpc-gettransfer)

### Information.

Informational API methods just return some information about the Dotmesh server.
They're not all that exciting or useful for most people, but they're a good place to start getting to grips with the API because of their simplicity.

#### DotmeshRPC.Ping.

Use this to check that the Dotmesh server is alive.
It doesn't do anything - it just returns the same response, to confirm that, yes, the server is running.

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Ping",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": "true",
  "id": 6129484611666146000
}
```

#### DotmeshRPC.CurrentUser.

This returns the details of the user making the request.
When used on your own cluster, it'll just return the details of the admin user, which isn't very interesting; but when used on the Hub, it will return some more interesting details.

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.CurrentUser",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": {
    "Id": "00000000-0000-0000-0000-000000000000",
    "Name": "admin",
    "Email": "",
    "EmailHash": "d41d8cd98f00b204e9800998ecf8427e",
    "CustomerId": "",
    "CurrentPlan": ""
  },
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Version.

This method returns the version of the Dotmesh server.
It's handy for checking if the server you're talking to supports some new feature you want, or to record the version number for informational purposes.

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Version",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": {
    "Name": "Dotmesh",
    "Version": "0.1",
    "Website": "https://dotmesh.io"
  },
  "id": 6129484611666146000
}
```

### User Account Control.

By using these API methods on the Dotmesh Hub, you can administer the user's account and add other users' accounts as collaborators to your dots.

#### DotmeshRPC.GetApiKey.

This method returns the user's API key. You can invoke it using the
API key or the user's password, but if you already know the API key,
there's not much point in using it to call this method to find it out
again; it's only really useful as a way to get the user's API key
given their password.

It is intended that passwords are never stored, only API keys. If
you're writing an interactive app that lets the user login, it's
recommended that you ask them for their username and password, then
use those to call this API method. If it succeeds, you can then store
the API key to use thereafter, and discard their password.

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.GetApiKey",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": {
    "ApiKey": "VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD"
  },
  "id": 6129484611666146000
}
```
#### DotmeshRPC.ResetApiKey.

Calling this method causes the user to be assigned a new, random API
key. This means that any attempt to use the previous API key will
fail; the new one returned by this method must be used in future.

This should be invoked if the user is worried their API key has been
compromised, or as part of a precautionary API key refresh, perhaps on
a regular schedule.

In order to limit the damage caused by a compromised API key, this
method can't be called using the API key - you need to use the
password!

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.ResetApiKey",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": {
    "ApiKey": "6SHK3KRVSHZJMHZMJ52GFYBQHGSDYTT46BPITJ2IXRUJCR4CH4MA===="
  },
  "id": 6129484611666146000
}
```

#### DotmeshRPC.AddCollaborator.

This API method on the Dotmesh Hub adds another user as a collaborator
onto a dot you own (the calling user *must* be the owner of the dot,
not a collaborator). To call it, you need the ID of the master branch
of the Dot, not its name; see [the `Lookup`
method](#dotmeshrpc-lookup) for a way to convert a name into an ID.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.AddCollaborator",
  "params": {
    "MasterBranchID": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
    "Collaborator": "alice"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

### Dot Management.

These API methods are used for managing dots. They are useful on both
a local cluster and the Dotmesh Hub.

When using these methods on a local cluster, the Namespace will always be `admin`.

When using these methods on the Hub, the Namespace will be the name of
the user that owns the Dot. Usually, that will be the same username as
the user calling the API methods, but it's possible to perform some
operations on a Dot you don't own if you've been [added as a
Collaborator](#dotmeshrpc-addcollaborator).

#### DotmeshRPC.Lookup.

This API method simply takes a dot name, and optionally also a branch
name, and converts it to a branch ID. If no branch name is given, it
returns the master branch ID of the dot.

##### Request.

On a local cluster, let's look up master branch ID of the `test` dot.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Lookup",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "Branch": ""
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Exists.

Although perhaps seemingly redundant given the [`Lookup`
method](#dotmeshrpc-lookup), this method simply checks if a given dot
(and, optionally, a specific branch of a dot) exists. If it does, it
returns the branch ID, just like `Lookup`; however, if it doesn't
exist, it just returns an empty string rather than an error. This
makes it handy for cases where non-existance of the dot/branch isn't an
error, to save you from having to convert an error back into a valid
value.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Exists",
  "params": {
    "Namespace": "admin",
    "Name": "non-existant-name",
    "Branch": ""
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": "",
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Get.

This method takes a branch ID and returns information about that
branch. We'll go through everything returned in the Response
section below.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Get",
  "params": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "Id": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
    "Name": {
      "Namespace": "admin",
      "Name": "test"
    },
    "Branch": "",
    "Master": "504954d09db78174",
    "SizeBytes": 19456,
    "DirtyBytes": 19456,
    "CommitCount": 0,
    "ServerStatuses": {
      "504954d09db78174": "active: waiting, 0 snaps (v740)"
    }
  },
  "id": 6129484611666146000
}
```

The result has the following keys:

<dl>

<dt><code>Id</code>.</dt>
<dd>This is just the branch ID, exactly as you provided in the request.</dd>

<dt><code>Name</code>.</dt>
<dd>This is the namespace and name of the Dot containing this branch.</dd>

<dt><code>Branch</code>.</dt>
<dd>If this is the master branch of the Dot, then `Branch` is an empty string. However, if we're dealing with a non-master branch, `Branch` will be its name.</dd>

<dt><code>Master</code>.</dt>
<dd>This is the ID of the node that's currently holding the live copy of this branch. Only that node may directly mount the branch into a container.</dd>

<dt><code>SizeBytes</code>.</dt>
<dd>The size of the branch, in bytes.</dd>

<dt><code>DirtyBytes</code>.</dt>
<dd>How much data has changed since the last commit (or creation) of this branch, in bytes.</dd>

<dt><code>CommitCount</code>.</dt>
<dd>How many commits have happened on this branch since its creation.</dd>

<dt><code>ServerStatuses</code>.</dt>
<dd>A map from the IDs of the nodes that have replicas of this branch, with a string summarising the status of the branch on that node for each.</dd>
</dl>

#### DotmeshRPC.List.

This method returns a list of available Dots. For each, it also
returns the ID of the currently selected branch for that Dot, and
the result of calling the [`Get` method](#dotmeshrpc-get) on it.

If you want the details of the master branch for each Dot, you're
going to need to spot the Dots that have a non-empty string for their
`Branch` key and call the [`Lookup` method](#dotmeshrpc-lookup) on the
name without a `Branch` to get the master branch ID, then call the
[`Get` method](#dotmeshrpc-get) to find the details.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.List",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "admin": {
      "test": {
        "Id": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
        "Name": {
          "Namespace": "admin",
          "Name": "test"
        },
        "Branch": "",
        "Master": "504954d09db78174",
        "SizeBytes": 19456,
        "DirtyBytes": 19456,
        "CommitCount": 0,
        "ServerStatuses": {
          "504954d09db78174": "active: waiting, 0 snaps (v740)"
        }
      }
    }
  },
  "id": 6129484611666146000
}
```

The result is a JSON object with a key per namespace - which will just
be `admin` for a local cluster. Within that key is an object with a
key per Dot, the contents of which is as per the result of the [`Get`
method](#dotmeshrpc-get).

#### DotmeshRPC.AllDotsAndBranches.

This API method returns a list of all the Dots and their branches, along
with lots of useful information.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.AllDotsAndBranches",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "Dots": [
      {
        "MasterBranch": {
          "Id": "1b950a95-cfc7-4ffc-40e3-e7ac5b2461d0",
          "Name": {
            "Namespace": "admin",
            "Name": "telescopes"
          },
          "Branch": "",
          "Master": "504954d09db78174",
          "SizeBytes": 19456,
          "DirtyBytes": 19456,
          "CommitCount": 0,
          "ServerStatuses": {
            "504954d09db78174": "active: waiting, 0 snaps (v880)"
          }
        },
        "OtherBranches": null,
        "Owner": {
          "Id": "00000000-0000-0000-0000-000000000000",
          "Name": "admin",
          "Email": "",
          "EmailHash": "d41d8cd98f00b204e9800998ecf8427e",
          "CustomerId": "",
          "CurrentPlan": ""
        },
        "Collaborators": []
      },
      {
        "MasterBranch": {
          "Id": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
          "Name": {
            "Namespace": "admin",
            "Name": "test"
          },
          "Branch": "",
          "Master": "504954d09db78174",
          "SizeBytes": 20480,
          "DirtyBytes": 0,
          "CommitCount": 1,
          "ServerStatuses": {
            "504954d09db78174": "active: waiting, 1 snaps (v1200)"
          }
        },
        "OtherBranches": [
          {
            "Id": "e1a9c58a-d80e-40c9-6474-e502cf6e79fa",
            "Name": {
              "Namespace": "admin",
              "Name": "test"
            },
            "Branch": "potatoes",
            "Master": "504954d09db78174",
            "SizeBytes": 1024,
            "DirtyBytes": 19456,
            "CommitCount": 0,
            "ServerStatuses": {
              "504954d09db78174": "active: waiting, 0 snaps (v850)"
            }
          },
          {
            "Id": "e495d3a3-9602-4049-49c1-81630815799e",
            "Name": {
              "Namespace": "admin",
              "Name": "test"
            },
            "Branch": "testing_v2",
            "Master": "504954d09db78174",
            "SizeBytes": 1024,
            "DirtyBytes": 19456,
            "CommitCount": 0,
            "ServerStatuses": {
              "504954d09db78174": "active: waiting, 0 snaps (v1205)"
            }
          }
        ],
        "Owner": {
          "Id": "00000000-0000-0000-0000-000000000000",
          "Name": "admin",
          "Email": "",
          "EmailHash": "d41d8cd98f00b204e9800998ecf8427e",
          "CustomerId": "",
          "CurrentPlan": ""
        },
        "Collaborators": [
          {
            "Id": "00000000-0000-0000-0000-000000000000",
            "Name": "admin",
            "Email": "",
            "EmailHash": "d41d8cd98f00b204e9800998ecf8427e",
            "CustomerId": "",
            "CurrentPlan": ""
          },
          {
            "Id": "00000000-0000-0000-0000-000000000000",
            "Name": "admin",
            "Email": "",
            "EmailHash": "d41d8cd98f00b204e9800998ecf8427e",
            "CustomerId": "",
            "CurrentPlan": ""
          }
        ]
      }
    ],
    "Servers": [
      {
        "Id": "504954d09db78174",
        "Addresses": [
          "192.168.1.34",
          "10.192.0.1",
          "172.18.0.1"
        ]
      }
    ]
  },
  "id": 6129484611666146000
}
```

Let's break down the keys in the result.

<dl>

<dt><code>Volumes</code>.</dt>

<dd>An array of the Dots in this cluster. Each is represented as a
JSON object, as described below.</dd>

<dt><code>Servers</code>.</dt>

<dd>An array of the servers in this cluster. Each is represented as a
JSON object, with an `Id` key containing the server ID and an
`Addresses` key containing a list of the IP addresses of that
server.</dd>

</dl>

Each Dot's information is given as a JSON object with the following keys:

<dl>

<dt><code>MasterBranch</code>.</dt>

<dd>This JSON object contains the details of the master branch of the Dot, as returned by the [`Get` method](#dotmeshrpc-get).</dd>

<dt><code>OtherBranches</code>.</dt>

<dd>This is an array of JSON objects, one for each non-master branch of the Dot, in the same format.</dd>

<dt><code>Owner</code>.</dt>

<dd>This is a JSON object, containing the details of the user that owns the Dot, as returned by the [`CurrentUser` method](#dotmeshrpc-currentuser).</dd>

<dt><code>Collaborators</code>.</dt>

<dd>This is an array of JSON objects, each containing the details of a collaborator assigned to this Dot with the [`AddCollaborator` method](#dotmeshrpc-addcollaborator), in the same format.</dd>

</dl>

#### DotmeshRPC.Create.

This method creates a new Dot, containing an empty master branch.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Create",
  "params": {
    "Namespace": "admin",
    "Name": "telescopes"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

The master branch ID isn't returned, so you'll need to call the
[`Lookup` method](#dotmeshrpc-lookup) if you need it.

#### DotmeshRPC.ContainersById.

This method returns a list of containers that are currently using the
specified branch (given the branch's ID).

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.ContainersById",
  "params": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": [
    {
      "Name": "/peaceful_hugle",
      "Id": "0306fc9d26684869b366ef3772f8d23bc7e19023f0e32e7f48d52b54dadf0a6f"
    }
  ],
  "id": 6129484611666146000
}
```

The `Name` and `Id` are as provided by Docker:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker ps --format '{{.ID}}  {{.Names}}'</kbd>
<em>0306fc9d2668</em>  <em>peaceful_hugle</em>
</pre></div>

#### DotmeshRPC.Containers.

This method performs exactly the same function as the
[`ContainersById` method](#dotmeshrpc-containersbyid), except that it
accepts a namespace/name/branch triple and effectively calls the
[`Lookup` method](#dotmeshrpc-lookup) for you to obtain the branch
ID.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Containers",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "Branch": ""
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": [
    {
      "Name": "/peaceful_hugle",
      "Id": "0306fc9d26684869b366ef3772f8d23bc7e19023f0e32e7f48d52b54dadf0a6f"
    }
  ],
  "id": 6129484611666146000
}
```

#### DotmeshRPC.CommitsById.

This API method returns a list of commits for a given branch, by ID.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.CommitsById",
  "params": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": [
    {
      "Id": "880fb2c4-24db-4d16-5fc4-974d17525450",
      "Metadata": {
        "author": "admin",
        "message": "A well-written commit message",
        "timestamp": "1516272712508219206"
      }
    }
  ],
  "id": 6129484611666146000
}
```

As you can see, each commit has its own ID, as well as metadata
including the username of the author, the message they supplied, and a
timestamp in UTC nanoseconds since the UNIX epoch.

#### DotmeshRPC.Commits.

This method performs exactly the same function as the
[`CommitsById` method](#dotmeshrpc-commitsbyid), except that it
accepts a namespace/name/branch triple and effectively calls the
[`Lookup` method](#dotmeshrpc-lookup) for you to obtain the branch
ID.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Commits",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "Branch": ""
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": [
    {
      "Id": "880fb2c4-24db-4d16-5fc4-974d17525450",
      "Metadata": {
        "author": "admin",
        "message": "A well-written commit message",
        "timestamp": "1516272712508219206"
      }
    }
  ],
  "id": 6129484611666146000
}
```
#### DotmeshRPC.Commit.

This API method triggers a commit on a given branch. Rather than
accepting a branch ID, it requires a namespace, dot name, and
optional branch name; it looks up the branch for you. You also need
to provide a commit message.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Commit",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "Branch": "",
    "Message": "A thoughtfully-written and clear commit message"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Rollback.

This API method reverts the current state of a branch back to a
previous commit. Rather than accepting a branch ID, it requires
a namespace, dot name, and optional branch name; it looks up the
branch for you. You also need to provide the ID of the commit to
roll back to, as returned by the [`Commits`
method](#dotmeshrpc-commits).

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Rollback",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "Branch": "",
    "CommitId": "880fb2c4-24db-4d16-5fc4-974d17525450"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Branches.

This API method returns a list of branches of a given Dot, given the namespace and name of the Dot.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Branches",
  "params": {
    "Namespace": "admin",
    "Name": "test"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": [
    "testing_v1",
    "testing_v2"
  ],
  "id": 6129484611666146000
}
```

The branch names can be converted into branch IDs by passing them
as the `Branch` parameter to the [`Lookup` method](#dotmeshrpc-lookup),
with the `Namespace` and `Name` of the Dot. Don't forget that every
Dot also has a master branch ID, obtained by calling `Lookup` with
an empty `Branch` name, as well as the branches listed by this method.

#### DotmeshRPC.Branch.

This API method creates a new branch for a given Dot, starting with an
existing commit of an existing branch. If you want to create a new
branch from the master branch of the Dot, you need to specify
`master` as the `SourceBranch` parameter; otherwise, you must specify
the name of the branch.

##### Request.

In this example, we create a branch called `testing_v2` from one of the
commits on the master branch we saw in the result from our
example call to the [`Commits` method](#dotmeshrpc-commits).

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Branch",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "SourceBranch": "master",
    "NewBranchName": "testing_v2",
    "SourceCommitId": "880fb2c4-24db-4d16-5fc4-974d17525450"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

#### DotmeshRPC.Delete.

This API method deletes a dot. There's no undo, so please don't call
it unless you mean it. You need to provide the namespace and name of
the dot.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Delete",
  "params": {
    "Namespace": "admin",
    "Name": "unwanted_things"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

### Attachment.

The attachment API methods relate to the attaching of volumes to
containers. Actually attaching a volume to a container can only be
done through the specialised Docker and Kubernetes integrations,
rather than this API; these API functions are *related* to attachment
rather than actually *performing* attachment.

A "volume" is an actual filesystem made available to a container; it
consists of a particular Subdot of a particular Branch of a particular
Dot.

#### DotmeshRPC.Procure.

This API method creates a Dot if required, makes sure the node
handling the API call is the master by migrating the Dot if necessary,
and returns the host path where the given Subdot of the Dot's current
branch (or a specific branch, if requested) is mounted.

The default Subdot is called `__default__`; use that for the
`Subdot` parameter unless the user specifies otherwise. Sending the
empty string as `Subdot` will cause the root of the Dot to be
mounted, which is conventionally what should happen if the user
specifies `__root__` as the Subdot name.

Normally, this API method will return a host path to the currently selected branch of the Dot, as selected by the [`SwitchContainers` method](#dotmeshrpc-switchcontainers); if that method has never been invoked, then this will be the master branch. However, any branch may be selected by specifying a `Name` of the form `NAME@BRANCH`, eg `test@testing_v1`; the branch name `master` may be used to request the master branch of the Dot.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Procure",
  "params": {
    "Namespace": "admin",
    "Name": "test@testing_v1"
    "Subdot": "__default__"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": "/var/dotmesh/admin/test@testing_v1/__default__",
  "id": 6129484611666146000
}
```

#### DotmeshRPC.SwitchContainers.

This API method changes the default branch for the given Dot. This
means that future calls to Procure, or attachments via the Docker or
Kubernetes integrations, that *do not* specify an explicit branch name
with the `NAME@BRANCH` syntax, will henceforth use the specified branch
rather than the original default of `master`.

In addition, any existing Docker containers using the default will be
stopped and re-started to use the new default when this API method is
called.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.SwitchContainers",
  "params": {
    "Namespace": "admin",
    "Name": "test",
    "NewBranchName": "testing_v2"
  },
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": true,
  "id": 6129484611666146000
}
```

### Transfers.

The transfer methods allow you to initiate pulls and pushes between Dotmesh clusters, including the Dotmesh Hub.

#### DotmeshRPC.Transfer.

This API method initiates a transfer - which can be a pull or a push -
with another cluster. To invoke it, you need to provide a hostname of
a node in the remote cluster, plus a username and an API key for that cluster.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Transfer",
  "params": {
    "Peer": "10.192.0.2",
    "User": "admin",
    "ApiKey": "MYRJNBIKDMT7OCAZYEHM2YITDS4TK3EY",
    "Direction": "push",
    "LocalNamespace": "admin",
    "LocalName": "volume_1",
    "LocalBranchName": "",
    "RemoteNamespace": "admin",
    "RemoteName": "volume_1",
    "RemoteBranchName": "",
    "TargetCommit": ""
  },
  "id": 5577006791947779000
}
```

The request has many parameters. Let's look at them in more detail.

<dl>

<dt><code>Peer</code>.</dt>
<dt><code>User</code>.</dt>
<dt><code>ApiKey</code>.</dt>

<dd>These are the details to connect to the remote cluster. `Peer` is
the hostname of a node in the remote cluster; for the Dotmesh Hub,
provide `secure:hub.datamesh.io`. FIXME: Make sure that's right when
we do the secure connectivity!</dd>

<dt><code>Direction</code>.</dt>

<dd>This should either be `"push"` or `"pull"`. You may not be
surprised to find out that `"push"` causes the cluster you send the
API request to to transfer a branch to the remote cluster, and that
`"pull"` causes it to request a branch from the remote cluster.</dd>

<dt><code>LocalNamespace</code>.</dt>
<dt><code>LocalName</code>.</dt>
<dt><code>LocalBranchName</code>.</dt>

<dd>These identify the branch on the local cluster - which may be
the source or target, depending on the `Direction`!</dd>

<dt><code>RmoteNamespace</code>.</dt>
<dt><code>RemoteName</code>.</dt>
<dt><code>RemoteBranchName</code>.</dt>

<dd>These identify the branch on the remote cluster - which also may be
the source or target, depending on the `Direction`!</dd>

<dt><code>TargetCommit</code>.</dt>

<dd>This is reserved for future use. Leave it as an empty string for now.</dd>

</dl>

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": "b655e1f4-ae90-422b-78ac-b1090c7391bb",
  "id": 5577006791947779000
}
```

The result is a transfer ID, which you can then poll with the
[`GetTransfer` method](#dotmeshrpc-gettransfer). Speaking of which...

#### DotmeshRPC.GetTransfer.

This API method checks the status of a transfer initiated with the
[`Transfer` method](#dotmeshrpc-transfer). To call it, you need the
transfer ID returned by `Transfer`.

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.GetTransfer",
  "params": "b655e1f4-ae90-422b-78ac-b1090c7391bb",
  "id": 8674665223082154000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "TransferRequestId": "b655e1f4-ae90-422b-78ac-b1090c7391bb",
    "Peer": "10.192.0.2",
    "User": "admin",
    "ApiKey": "MYRJNBIKDMT7OCAZYEHM2YITDS4TK3EY",
    "Direction": "push",
    "LocalNamespace": "admin",
    "LocalName": "volume_1",
    "LocalBranchName": "",
    "RemoteNamespace": "admin",
    "RemoteName": "volume_1",
    "RemoteBranchName": "",
    "FilesystemId": "3d55917d-a742-4afa-57ec-207fd589da3c",
    "InitiatorNodeId": "cc35b6b4c2edbd4d",
    "PeerNodeId": "",
    "StartingCommit": "START",
    "TargetCommit": "b0af7015-9a01-497e-6249-8cf973fb3bd2",
    "Index": 1,
    "Total": 1,
    "Status": "finished",
    "NanosecondsElapsed": 37419551,
    "Size": 9728,
    "Sent": 44939,
    "Message": ""
  },
  "id": 8674665223082154000
}
```

We won't explain all of them in detail, as they may change in
future. As you can see, many of them are copies of the original
transfer request parameters. The one important thing you need to know
is that when the `Status` key becomes `finished`, it's done!

