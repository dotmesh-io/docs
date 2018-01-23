+++
draft = false
title = "What is a Datadot"
synopsis = "Datadots, commits, subdots, branches."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "concepts"
+++

## Datadots

A Datadot allows you to capture your entire application's state and treat it like a `git` repo.

A simple example is to start a Redis container using a Datadot called `myapp`:

```bash
docker run -d -v myapp:/data --volume-driver dm redis
```

This creates a datadot called `myapp`, creates the default `master` branch in that datadot, mounts the `master` branch into `/data` in the `redis` container, and starts the `redis` container, like this:

<img src="/hugo/what-is-a-datadot-01-myapp-dot.png" alt="myapp dot with master branch and redis container's /data volume attached" style="width: 50%;" />

You can see this in the `dm list` output:

## Commits

You can commit a datadot with:

```bash
dm switch myapp
dm commit -m "Empty state."
```


## Subdots

Modern apps often have more than one database, cache or queue.
A datadot can capture all of those states in a single, atomically consistent commit.

A datadot might be named with your application:

* `sockshop`

That dot's subdots are named with a `.`:

* `sockshop.orders-db`
* `sockshop.catalog-db`

And so on, for the different microservices in `sockshop`.


## Branches

Just like `git`, you can make a branch from a commit on a datadot.

```bash
dm checkout -b bug-16637
dm commit -m "[...]"
```


## Pushing

If you, `pete`, want to make your dot available to others, push it:

```bash
dm remote add hub pete@dothub.com
dm push sockshop hub
```


## Cloning & pulling

If you, `lukemarsden`, have collaborator access to a colleague `pete`'s dot `sockshop`, you can clone it with:

```bash
dm clone lukemarsden@dothub.com:pete/sockshop
```

Later, if `pete` pushes new commits, you can pull them into your local `sockshop` dot with:

```bash
dm pull hub sockshop
```

## Further reading

* See also: [Hello Dotmesh Tutorial](/tutorials/hello-dotmesh-docker/)
* See also: [Docker Compose reference](/references/docker-compose/)
