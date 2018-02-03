+++
draft = false
title = "Using dots in Kubernetes"
synopsis = "Adding dots to Kubernetes YAML files."
knowledgelevel = ""
date = 2017-12-20T11:17:29Z
[menu]
  [menu.main]
    parent = "tasks"
+++

## Using Dotmesh in Kubernetes

The [default YAML](/install-setup/kubernetes/) registers a StorageClass called `dotmesh` that you can use in your PersistentVolumeClaims.
For instance:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-exciting-data
spec:
  storageClassName: dotmesh
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

This will use a dot called `my-exciting-data`, creating it automatically if it doesn't exist.

You can also specify a [subdot](/concepts/what-is-a-datadot/#subdots):

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-exciting-data
  annotations:
    dotmeshName: myapp
    dotmeshSubdot: db
spec:
  storageClassName: dotmesh
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

In that case, the volume will be mounted from the subdot `db` of the dot `myapp`.
