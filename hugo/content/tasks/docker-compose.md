+++
draft = false
title = "Docker Compose"
synopsis = "Adding dots to Docker Compose files."
knowledgelevel = ""
date = 2017-12-20T11:17:29Z
[menu]
  [menu.main]
    parent = "tasks"
+++

## Docker Compose v1

Assuming you have a `demo` app which has services defined in a Docker Compose v1 file:

```yaml
web:
  build: .
  ports:
   - "5000:5000"
redis:
  image: "redis:alpine"
```

To dotmesh-enable the `redis`, simply add these three lines at the bottom of the file:

```yaml
web:
  build: .
  ports:
   - "5000:5000"
redis:
  image: "redis:alpine"
  volume_driver: dm
  volumes:
   - "demo.redis:/data"
```

Note that this example creates a dot called `demo` with a [subdot](/concepts/what-is-a-datadot/#subdots) called `redis`.

## Docker Compose v2 and v3

Define your volumes centrally under the top-level `volumes`, then refer to them by name in your services.

For example, starting with a file that looks like:

```yaml
version: '3'

services:
  web:
    build: .
    ports:
     - "5000:5000"
  redis:
    image: "redis:alpine"
```

Update it accordingly:

```yaml
version: '3'

volumes:
  demo.redis:
    driver: dm

services:
  web:
    build: .
    ports:
     - "5000:5000"
  redis:
    image: "redis:alpine"
    volumes:
     - "demo.redis:/data"
```

This works in the same way for Docker Compose v2 and v3 files.
