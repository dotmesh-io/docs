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

All API methods are invoked by making a POST to `http://SERVERNAME:6969/rpc`, with Basic HTTP authentication. To talk to your local cluster, you'll need the `admin` user and the corresponding API key.
If you created your cluster from the command line with `dm cluster init`, these can be found in the `$HOME/.dotmesh/config` file:

<div class="highlight"><pre class="chromaManual">
$ <kbd>cat ~/.dotmesh/config | jq .Remotes.local.ApiKey</kbd>
"<em>VVKGYCC3G4K5G2QM3GLIVTECVSBWWJZD</em>"
</pre></div>

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

It's also possible to authenticate to the API by submitting a user's password instead of their API key.
The password is intended for use when users log into administrative interfaces and supply their username and password through a login screen, rather than being stored; API keys are intended to be stored, and can be easily revoked by the user, so most uses of the API should use an API key instead.
The one exception is API methods to manage the user account, which are explicitly prohibited from use with just an API key, so that a lost API key is not able to permanently compromise an account. These will be discussed below.

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

The dotmesh API contains a whole load of different methods, so let's look at them in related groups. We'll start with the simplest!

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
not a collaborator). To call it, you need the ID of the master
filesystem of the Dot, not its name; see [the `Lookup`
method](#dotmeshrpc-lookup) for a way to convert a name into an ID.

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

These API methods are used for managing dots. They are useful on both
a local cluster and the Dotmesh Hub.

When using these methods on a local cluster, the Namespace will always be `admin`.

When using these methods on the Hub, the Namespace will be the name of
the user that owns the Dot. Usually, that will be the same username as
the user calling the API methods, but it's possible to perform some
operations on a Dot you don't own if you've been [added as a
Collaborator](#dotmeshrpc-addcollaborator).

#### DotmeshRPC.Lookup.

This API method simply takes a dot name, and optionally also a clone
name, and converts it to a filesystem ID. If no clone name is given,
it returns the master filesystem ID of the dot, which is the ID of the
dot itself; however, if a clone name is given, you just get the
filesystem ID of the clone, which is different to the master
filesystem ID.

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

Although perhaps seemingly redundant given the [`Lookup`
method](#dotmeshrpc-lookup), this method simply checks if a given dot
(and, optionally, a specific clone of a dot) exists. If it does, it
returns the filesystem ID, just like `Lookup`; however, if it doesn't
exist, it just returns an empty string rather than an error. This
makes it handy for cases where non-existance of the dot/clone isn't an
error, to save you from having to convert an error back into a valid
value.

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

<dt>`Id`.</dt>
<dd>This is just the filesystem ID, exactly as you provided in the request.</dd>

<dt>`Name`.</dt>
<dd>This is the namespace and name of the Dot containing this filesystem.</dd>

<dt>`Clone`.</dt>
<dd>If this is the master filesystem of the Dot, then `Clone` is an empty string. However, if we're dealing with a clone, `Clone` will be its name.</dd>

<dt>`Master`.</dt>
<dd>This is the ID of the node that's currently holding the live copy of this filesystem. Only that node may directly mount the filesystem into a container.</dd>

<dt>`SizeBytes`.</dt>
<dd>The size of the filesystem, in bytes.</dd>

<dt>`DirtyBytes`.</dt>
<dd>How much data has changed since the last commit (or creation) of this filesystem, in bytes.</dd>

<dt>`CommitCount`.</dt>
<dd>How many commits have happened on this filesystem since its creation.</dd>

<dt>`ServerStatuses`.</dt>
<dd>A map from the IDs of the nodes that have replicas of this filesystem, with a string summarising the status of the filesystem on that node for each.</dd>
</dl>


#### DotmeshRPC.List.

This method returns a list of available Dots. For each, it also
returns the ID of the currently selected filesystem for that Dot, and
the result of calling the [`Get` method](#dotmeshrpc-get) on it.

If you want the details of the master filesystem for each Dot, you're
going to need to spot the Dots that have a non-empty string for their
`Clone` key and call the [`Lookup` method](#dotmeshrpc-lookup) on the
name without a `Clone` to get the master filesystem ID, then call the
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

#### DotmeshRPC.Create.

This method creates a new Dot, containing an empty filesystem.

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

The master filesystem ID isn't returned, so you'll need to call the
[`Lookup` method](#dotmeshrpc-lookup) if you need it.

#### DotmeshRPC.ContainersById.

This method returns a list of containers that are currently using the
specified filesystem (given the filesystem's ID).

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
accepts a namespace/name/clone triple and effectively calls the
[`Lookup` method](#dotmeshrpc-lookup) for you to obtain the filesystem
ID.

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

TODO:

func (d *DotmeshRPC) SnapshotsById(
func (d *DotmeshRPC) Snapshots(
func (d *DotmeshRPC) Snapshot(
func (d *DotmeshRPC) Rollback(
func (d *DotmeshRPC) Clones(r *http.Request, filesystemName *VolumeName, result *[]string) error {
func (d *DotmeshRPC) Clone(
func (d *DotmeshRPC) AllVolumesAndClones(
func (d *DotmeshRPC) DeleteVolume(


### Transfers.

TODO:


func (d *DotmeshRPC) RegisterFilesystem(
func (d *DotmeshRPC) GetTransfer(
func (d *DotmeshRPC) RegisterTransfer(
func (d *DotmeshRPC) Transfer(
func (d *DotmeshRPC) DeducePathToTopLevelFilesystem(
func (d *DotmeshRPC) PredictSize(


### Procurement.

TODO: 


func (d *DotmeshRPC) Procure(
func (d *DotmeshRPC) SwitchContainers(


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
