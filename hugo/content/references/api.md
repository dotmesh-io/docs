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

# Overview
The dotmesh API is the fundamental way of interacting with dotmesh, the service.

Before attempting to use the API, we recommend understanding the [dotmesh architecture](FIXME).

Any time you interact with any part of dotmesh - whether a local deployment or the dotmesh hub - you are using the API. Our Web UI for dotmesh hub, the `dm` command-line interface, any interaction between a local deployment and the hub, all use the same, publicly-exposed dotmesh API.

This document describes the API in its entirety. With this API, you not only can understand how to interact with dotmesh, but you can write your own clients and connect your own services. In fact, we **encourage** you to do so and would be happy to publish it, if you want.

## API Target
When using the dotmesh API, you need a server endpoint with which you will communicate. You have two choices:

* dotmesh local: If you are running dotmesh locally, then you can make API calls to your local dotmesh implementation. Only dotmesh cluster commands will work here; dotmush hub commands will be rejected.
* dotmesh hub: You can make all hub commands to the dotmesh hub, and most, but not all, cluster commands.

Each API call is prefaced with a section indicating if it applies to dotmesh hub, dotmesh local or both.

### Local
As described in the [architecture documentation](FIXME), dotmesh is installed as software running on one or many server nodes. For example, in kubernetes, it will be deployed as a `DaemonSet` running on every node in your cluster.

There are two types of local API calls: cluster and node.

* Cluster: The overwhelming majority of API calls are cluster-level calls. They operate on any or every node of the cluster. Once any one node processes the call, it will ensure that all of the nodes in the cluster are aware of the new state, if any.  Thus, in general, an API command, including those performed by the `dm` CLI, may be sent to any one node. It then will be routed to all of the other nodes as needed, and the entire cluster of nodes will be aware.
* Node: A subset of calls are node-specific, e.g. mounting a volume from a dot. Since a mount happens on a particular node, the API call needs to be sent to the server running on the actual node on which the volume is to be mounted. These calls rarely are made by clients. Instead, they are called by drivers for specific implementations, for example a Kubernetes `kubelet`, which calls the dotmesh driver to mount a specific volume from a specific dot on a specific node, which the `kubelet` already is aware.

Each dotmesh instance exposes the dotmesh API on port 6969.

In a Kubernetes cluster, you can access the dotmesh `Service` from any `Pod` in the Kubernetes cluster. The service name is `dotmesh` in the `dotmesh` namespace by default, which can be accessed through [the standard Kubernetes service discovery methods](https://kubernetes.io/docs/concepts/services-networking/service/#discovering-services). Thus it will be available at `dotmesh.dotmesh:6969`.

### Hub
The dotmesh hub API is available at https://hub.dotmesh.io . Note that the Hub API is available over https, rather than http, and is exposed at port 443.

## Protocol
The dotmesh API is a json-rpc protocol over http.

All API methods are invoked by making a POST to the target endpoint, e.g. http://dotmesh.dotmesh:6969 or https://hub.dotmesh.io at the path `/rpc`, with Basic HTTP authentication.


### Authentication
API calls _always_ require authentication. The credentials you use depend on which API target you are talking to.

#### Hub
If you are communicating with the dotmesh hub, you can use the API or Web UI to retrieve your credentials. These will consist of a username and API token.

It's possible to authenticate to the API by submitting a user's password instead of their API key.
The password is intended for use when users log into administrative interfaces and supply their username and password through a login screen, rather than being stored; API keys are intended to be stored, and can be easily revoked by the user, so most uses of the API should use an API key instead.
The one exception is API methods to manage the user account, which are explicitly prohibited from use with just an API key, so that a lost API key is not able to permanently compromise an account. These will be discussed below.

#### Local
If you are communicating with a local cluster you will have a single username `admin` and a single available API key. You can retrieve the key in a number of ways, depending on how you created your dotmesh cluster.


##### CLI
If you created your cluster from the command line with `dm cluster init`, these can be found in the `$HOME/.dotmesh/config` file:

<div class="highlight"><pre class="chromaManual">
$ <kbd>cat ~/.dotmesh/config | jq .Remotes.local.ApiKey</kbd>
"<em>VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD</em>"
</pre></div>

#### Kubernetes
If your cluster was created purely through Kubernetes, the admin API key can be found in the `dotmesh-api-key.txt` key in the `dotmesh` secret, in the `dotmesh` namespace:

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

### Format
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

## API reference.

The dotmesh API encompasses many different methods. This section organizes them into related groups.

* System Information
* User Account Management
* Dot Management
* Volume Attachment
* Dot Transfers

### Information
Informational API methods return information about the dotmesh cluster, its users, and individual instances.
They're not all that exciting or useful for most people, but they're a good place to start getting to grips with the API because of their simplicity.

#### DotmeshRPC.Ping.

Use this to check that the Dotmesh server is alive.
It doesn't do anything - it just returns the same response, to confirm that, yes, the server is running.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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

### User Account Management

These API methods on the Dotmesh Hub administer the user's account and add other users' accounts as collaborators to your dots.

#### DotmeshRPC.GetApiKey

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

[FIXME: These need formatting]
Availability:
* Local: NO
* Hub: YES

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

[FIXME: These need formatting]
Availability:
* Local: NO
* Hub: YES

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
not a collaborator). To call it, you need the ID of the master
filesystem of the Dot, not its name; see [the `Lookup`
method](#dotmeshrpc-lookup) for a way to convert a name into an ID.

[FIXME: These need formatting]
Availability:
* Local: NO
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.AddCollaborator",
  "params": {
    "Volume": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
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

These API methods are used for managing dots, available both on a local cluster and the Dotmesh Hub.

When using these methods on a local cluster, the Namespace always will be `admin`.

When using these methods on the Hub, the Namespace will be the name of
the user that owns the Dot. Usually, that will be the same username as
the user calling the API methods, but it's possible to perform some
operations on a Dot you don't own if you've been [added as a
Collaborator](#dotmeshrpc-addcollaborator), or with Organizations.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

#### DotmeshRPC.Lookup.

This API method simply takes a dot name, and optionally also a clone
name, and converts it to a filesystem ID. If no clone name is given,
it returns the master filesystem ID of the dot, which is the ID of the
dot itself; however, if a clone name is given, you just get the
filesystem ID of the clone, which is different to the master
filesystem ID.

[FIXME: I don't get what a "filesystem ID" is. I get a dot, and that it can have a name (luke/foo) which translates to a UUID, but what is a "filesystem ID"? Using "filesystem" makes it seem like it conflicts with dot concepts? And what is a "clone"? Isn't that just another dot?]

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

On a local cluster, let's look up master filesystem ID of the `test` dot.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Lookup",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CloneName": ""
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

Checks if a given dot (and, optionally, a specific clone of a dot) exists. If it does, it
returns the filesystem ID; if it doesn't
exist, it just returns an empty string.

This is functionally equivalent to `Lookup`, except that the non-existent case is handled
by returning an empty string rather than an error, as `Lookup` would.
This is just a convenience method, to save you from having to convert an error back into a valid value.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Exists",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "non-existant-name",
    "CloneName": ""
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

This method takes a filesystem ID and returns information about that
filesystem. We'll go through everything returned in the Response
section below.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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
    "Clone": "",
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
<dd>This is just the filesystem ID, exactly as you provided in the request.</dd>

<dt><code>Name</code>.</dt>
<dd>This is the namespace and name of the Dot containing this filesystem.</dd>

<dt><code>Clone</code>.</dt>
<dd>If this is the master filesystem of the Dot, then `Clone` is an empty string. However, if we're dealing with a clone, `Clone` will be its name.</dd>

<dt><code>Master</code>.</dt>
<dd>This is the ID of the node that's currently holding the live copy of this filesystem. Only that node may directly mount the filesystem into a container.</dd>

<dt><code>SizeBytes</code>.</dt>
<dd>The size of the filesystem, in bytes.</dd>

<dt><code>DirtyBytes</code>.</dt>
<dd>How much data has changed since the last commit (or creation) of this filesystem, in bytes.</dd>

<dt><code>CommitCount</code>.</dt>
<dd>How many commits have happened on this filesystem since its creation.</dd>

<dt><code>ServerStatuses</code>.</dt>
<dd>A map from the IDs of the nodes that have replicas of this filesystem, with a string summarising the status of the filesystem on that node for each.</dd>
</dl>

#### DotmeshRPC.List.

This method returns a list of Dots. For each, it also
returns the ID of the currently selected filesystem for that Dot, and
the result of calling the [`Get` method](#dotmeshrpc-get) on it.

The list of dots returned will include _only_ those dots for whom the querying user has access:

* Hub: The ones in your namespace and those for which you have been added as a collaborator.
* Local: All dots

If you want the details of the master filesystem for each Dot, you're
going to need to spot the Dots that have a non-empty string for their
`Clone` key and call the [`Lookup` method](#dotmeshrpc-lookup) on the
name without a `Clone` to get the master filesystem ID, then call the
[`Get` method](#dotmeshrpc-get) to find the details.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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
        "Clone": "",
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

#### DotmeshRPC.AllVolumesAndClones.

This API method returns a list of all the Dots and their clones, along
with lots of useful information.

The list of dots returned will include _only_ those dots for whom the querying user has access:

* Hub: The ones in your namespace and those for which you have been added as a collaborator.
* Local: All dots

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES


##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.AllVolumesAndClones",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "Volumes": [
      {
        "TopLevelVolume": {
          "Id": "1b950a95-cfc7-4ffc-40e3-e7ac5b2461d0",
          "Name": {
            "Namespace": "admin",
            "Name": "telescopes"
          },
          "Clone": "",
          "Master": "504954d09db78174",
          "SizeBytes": 19456,
          "DirtyBytes": 19456,
          "CommitCount": 0,
          "ServerStatuses": {
            "504954d09db78174": "active: waiting, 0 snaps (v880)"
          }
        },
        "CloneVolumes": null,
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
        "TopLevelVolume": {
          "Id": "b225158d-a2ac-4738-6d31-9a7dc511aab5",
          "Name": {
            "Namespace": "admin",
            "Name": "test"
          },
          "Clone": "",
          "Master": "504954d09db78174",
          "SizeBytes": 20480,
          "DirtyBytes": 0,
          "CommitCount": 1,
          "ServerStatuses": {
            "504954d09db78174": "active: waiting, 1 snaps (v1200)"
          }
        },
        "CloneVolumes": [
          {
            "Id": "e1a9c58a-d80e-40c9-6474-e502cf6e79fa",
            "Name": {
              "Namespace": "admin",
              "Name": "test"
            },
            "Clone": "potatoes",
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
            "Clone": "testing_v2",
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

<dt><code>TopLevelVolume</code>.</dt>

<dd>This JSON object contains the details of the master filesystem of the Dot, as returned by the [`Get` method](#dotmeshrpc-get).</dd>

<dt><code>CloneVolumes</code>.</dt>

<dd>This is an array of JSON objects, one for each clone filesystem of the Dot, in the same format.</dd>

<dt><code>Owner</code>.</dt>

<dd>This is a JSON object, containing the details of the user that owns the Dot, as returned by the [`CurrentUser` method](#dotmeshrpc-currentuser).</dd>

<dt><code>Collaborators</code>.</dt>

<dd>This is an array of JSON objects, each containing the details of a collaborator assigned to this Dot with the [`AddCollaborator` method](#dotmeshrpc-addcollaborator), in the same format.</dd>

</dl>

#### DotmeshRPC.Create.

This method creates a new Dot, containing an empty filesystem. The dot will be created in the namespace
provided in the request. If you do *not* have creation rights in that namespace, the response will be an error.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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

[FIXME: Does not yet return filesystem ID, but will.]

#### DotmeshRPC.ContainersById.

This method returns a list of containers that are currently using the
specified filesystem, given the filesystem's ID.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

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

This method returns a list of containers that are currently using the
specified filesystem, given a namespace/name/clone tuple. it is
functionally equivalent to
[`ContainersById` method](#dotmeshrpc-containersbyid), useful if you do not have the filesystem I,
saving you the `Lookup`.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Containers",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CloneName": ""
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

#### DotmeshRPC.SnapshotsById.

This API method returns a list of snapshots for a given filesystem, by ID.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.SnapshotsById",
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

#### DotmeshRPC.Snapshots.

This API method returns a list of snapshots for a given filesystem, by namespace/name/clone tuple.
It is a convenience method, useful when you do not have the filesystem ID.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Snapshots",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CloneName": ""
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
#### DotmeshRPC.Snapshot.

This API method triggers a commit on a given filesystem. Rather than
accepting a filesystem ID, it requires a namespace, dot name, and
optional clone name; it looks up the filesystem for you. You also need
to provide a commit message.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Snapshot",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CloneName": "",
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

This API method reverts the current state of a filesystem back to a
previous snapshot. Rather than accepting a filesystem ID, this call accepts
`namespace`, `dot_name` and optional `clone name` parameters, and looks up the
filesystem for you. You also need to provide the ID of the snapshot to
roll back to, as returned by the [`Snapshots`
method](#dotmeshrpc-snapshots).

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Rollback",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CloneName": "",
    "SnapshotId": "880fb2c4-24db-4d16-5fc4-974d17525450"
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

#### DotmeshRPC.Clones.

This API method returns a list of clones of a given Dot, given the namespace and name of the Dot.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Clones",
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

The clone names can be converted into filesystem IDs by passing them
as the `Clone` parameter to the [`Lookup` method](#dotmeshrpc-lookup),
with the `Namespace` and `Name` of the Dot. Don't forget that every
Dot also has a master filesystem ID, obtained by calling `Lookup` with
an empty `Clone` name, as well as the clones listed by this method.

#### DotmeshRPC.Clone.

This API method creates a new clone for a given Dot, starting with an
existing commit of an existing clone. If you want to create a new
clone from the master filesystem of the Dot, you need to specify
`master` as the `SourceBranch` parameter; otherwise, you must specify
the name of the clone.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

In this example, we create a clone called `testing_v2` from one of the
snapshots on the master filesystem we saw in the result from our
example call to the [`Snapshots` method](#dotmeshrpc-snapshots).

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Clone",
  "params": {
    "Namespace": "admin",
    "Volume": "test",
    "SourceBranch": "master",
    "NewBranchName": "testing_v2",
    "SourceSnapshotId": "880fb2c4-24db-4d16-5fc4-974d17525450"
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

#### DotmeshRPC.DeleteVolume.

This API method deletes a dot. There's no undo, so please don't call
it unless you mean it. You need to provide the namespace and name of
the dot.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: YES

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.DeleteVolume",
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

### Attachment

The attachment API methods relate to the attaching of volumes to
containers. Actually attaching a volume to a container can only be
done through the specific platform integrations, e.g. Docker and Kubernetes,
rather than this API; these API functions are *related* to attachment
rather than actually *performing* attachment.

#### DotmeshRPC.Procure.

This API method creates a Dot if required, ensures the node
handling the API call is the master by migrating the Dot if necessary,
and returns the host path where the given Subdot of the Dot's current
branch (or a specific branch, if requested) is mounted.

The default Subdot is called `__default__`; use that for the
`Subvolume` parameter unless the user specifies otherwise. Sending the
empty string as `Subvolume` will cause the root of the `Dot` to be
mounted, which is conventionally what should happen if the user
specifies `__root__` as the Subdot name.

Normally, this API method will return a host path to the currently selected filesystem of the Dot, as selected by the [`SwitchContainers` method](#dotmeshrpc-switchcontainers); if that method has never been invoked, then this will be the master filesystem. However, any filesystem may be selected by specifying a `Name` of the form `NAME@CLONE`, eg `test@testing_v1`; the clone name `master` may be used to request the master filesystem of the Dot.

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: NO

##### Request.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Procure",
  "params": {
    "Volume": {
      "Namespace": "admin",
      "Name": "test@testing_v1"
    },
    "Subvolume": "__default__"
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

This API method changes the default clone for the given Dot. This
means that future calls to Procure, or attachments via the Docker or
Kubernetes integrations, that *do not* specify an explicit clone name
with the `NAME@CLONE` syntax, will henceforth use the specified clone
rather than the original default of `master`. [FIXME: Should an API **ever** have a default clone?
Convenience defaults work for CLIs and UIs, but should APIs not **always** be explicit?]

In addition, any existing Docker containers using the default will be
stopped and re-started to use the new default when this API method is
called. [FIXME: Do we want this? Should we be interacting destructively with containers this way?]

[FIXME: These need formatting]
Availability:
* Local: YES
* Hub: NO

##### Request.

The `CurrentCloneName` parameter is reserved for future use. Please
leave it blank for now.

```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.SwitchContainers",
  "params": {
    "Namespace": "admin",
    "TopLevelFilesystemName": "test",
    "CurrentCloneName": "",
    "NewCloneName": "testing_v2"
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

TODO:


func (d *DotmeshRPC) RegisterFilesystem(
func (d *DotmeshRPC) GetTransfer(
func (d *DotmeshRPC) RegisterTransfer(
func (d *DotmeshRPC) Transfer(
func (d *DotmeshRPC) DeducePathToTopLevelFilesystem(
func (d *DotmeshRPC) PredictSize(



### ALARIC'S WORK IN PROGRESS NOTES.

How to test RPCs from the command line to get sample results:

```bash
curl --user admin:VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD -H "Content-Type: application/json" http://localhost:6969/rpc --data-binary '{"jsonrpc":"2.0","method":"DotmeshRPC.CurrentUser","params":{},"id": 6129484611666146000}' | jq .
```

func (d *DotmeshRPC) SubmitPayment(
func (d *DotmeshRPC) SetDebugFlag(


#### DotmeshRPC.Config.

This method returns selected configuration from the Dotmesh cluster.
(FIXME: I really have no idea how to justify this to third-party developers. From what it returns, it looks like it's used as part of the stripe integration?)

##### Request.
```json
{
  "jsonrpc": "2.0",
  "method": "DotmeshRPC.Config",
  "params": {},
  "id": 6129484611666146000
}
```

##### Response.
```json
{
  "jsonrpc": "2.0",
  "result": {
    "Plans": null,
    "StripePublicKey": ""
  },
  "id": 6129484611666146000
}
```
