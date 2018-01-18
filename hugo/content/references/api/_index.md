+++
draft = false
title = "API Reference"
synopsis = "Take control of Dotmesh"
knowledgelevel = ""
date = 2018-01-17T12:04:35Z
order = "3"
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

TODO:

func (d *DotmeshRPC) GetApiKey(
func (d *DotmeshRPC) ResetApiKey(
func (d *DotmeshRPC) AddCollaborator(

### Volume Management.

TODO:

func (d *DotmeshRPC) Exists(
func (d *DotmeshRPC) Get(
func (d *DotmeshRPC) List(
func (d *DotmeshRPC) Create(
func (d *DotmeshRPC) Containers(
func (d *DotmeshRPC) ContainersById(
func (d *DotmeshRPC) Lookup(
func (d *DotmeshRPC) Snapshots(
func (d *DotmeshRPC) SnapshotsById(
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

