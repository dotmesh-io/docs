+++
draft = false
title = "What is a Datadot"
synopsis = "Datadots, commits, subdots, branches, pushing & pulling."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "concepts"
+++

_Want to try the examples here without [installing Dotmesh](/install-setup)?_
_Try running the commands in our [online learning environment](TODO Katacoda)._

## Datadots

A Datadot allows you to capture your application's state and treat it like a `git` repo.

A simple example is to start a PostgreSQL container using a Datadot called `myapp`:

```bash
docker run -d --volume-driver dm \
    -v myapp:/var/lib/postgres/data --name postgres postgres
```

This creates a datadot called `myapp`, creates the writeable filesystem for the default `master` branch in that datadot, mounts the writeable filesystem for the `master` branch into `/var/lib/postgres/data` in the `postgres` container, and starts the `postgres` container, like this:

<img src="/hugo/what-is-a-datadot-01-myapp-dot.png" alt="myapp dot with master branch and postgres container's /data volume attached" style="width: 80%;" />

You can see this in the `dm list` output:

```bash
dm list
```

```plain
  DOT      BRANCH  SERVER   CONTAINERS  SIZE       COMMITS  DIRTY
* myapp    master  a1b2c3d  /postgres   19.00 kiB  0        19.00 kiB
```
The current branch is shown in the `BRANCH` column and the current dot is marked with a `*` in the `dm list` output.

## Commits

You can commit a datadot by switching to it, which, like `cd`'ing into a git repo, makes it the "current" dot:

```bash
dm switch myapp
```

And then creating a new commit:

```bash
dm commit -m "empty state"
```

This creates a commit: a point-in-time snapshot of the state of the filesystem on the current branch for the current dot.

Suppose PostgreSQL then writes some data to the docker volume.
You can then capture this new state in another commit with:

```bash
dm commit -m "some data"
```

There will then be two commits, frozen point-in-time snapshots, that were created from the state of the `master` branch at the point in time when they were created:

<img src="/hugo/what-is-a-datadot-02-myapp-commits.png" alt="two commits on the master branch" style="width: 80%;" />

You can confirm this in the output of:

```bash
dm log
```

```plain
TODO: capture dm log output
```

### Consistency

Commits are made immediately and atomically: they are "consistent snapshots" in the sense used [in the PostgreSQL documentation](https://www.postgresql.org/docs/current/static/backup-file.html).

It's safe to create a commit while a database is running as long as the database supports recovering from a power outage.

### Rollback

Given the example above, you can roll back to the first commit with:

```bash
dm reset --hard HEAD^
```

`HEAD^` means "one commit before the latest commit on the current branch".
You can also do `dm log` and refer to commits by id.

Note that rolling back stops the containers using a branch before the rollback, and starts them again afterwards.
Otherwise, the database would be confused by its data directory changing "under its feet".

Note also that a rollback is *destructive* -- the commits after the commit that is rolled back to are irretrievably destroyed.

## Subdots

Microservices applications often have more than one stateful component, e.g. databases, caches and queues.
A datadot can capture all of those states in a single, atomic and consistent commit.

A datadot might be named with your application:

* `myapp`

Assume that your app has an `orders` service with an `orders-db`, and a `catalog` service with a `catalog-db`.

In this case, name your dots as follows.
A `.` character is used to separated the dot name from the subdot name.

* `myapp.orders-db`
* `myapp.catalog-db`

Example Docker Compose syntax would be:

```yaml
  # ...
  orders-db:
    image: mongo:3.4
    hostname: orders-db
    volume_driver: dm
    volume: myapp.orders-db:/data/db
  # ...
  catalog-db:
    image: mysql:5.6
    hostname: catalog-db
    volume: myapp.catalog-db:/var/lib/mysql
  # ...
```

Starting the above Docker Compose file would create a dot with the following structure:

<img src="/hugo/what-is-a-datadot-03-myapp-subdots.png" alt="a dot with an orders-db and catalog-db subdots" style="width: 80%;" />

The subdots are "partitions" of the master branch's writeable filesystem so that different containers can have different parts of it.

Commits and branches of a datadot apply to the _entire_ datadot, not specific subdots.
This means that your datadot commits can represent snapshots of the state of your _entire application_, not the individual data services.

See the [subdots tutorial](TODO) for a more complete example.


## Branches

Just like `git`, you can make a branch from a commit on a datadot.
You can checkout a branch and create it at the same time with:

```bash
dm checkout -b bug-16637
```

Then suppose you make some changes to the current dot by interacting with the app, which modifies its databases.
You can then capture these changes:

```bash
dm commit -m "Reproducer for bug 16637"
```

Finally, you can go back to the original `master` branch:

```bash
dm checkout master
```

When switching branches on a dot, containers that are using the dot are stopped, the branch is switched out underneath them, and then the containers are started again.

If you want to disable this behavior, you can pin a branch by specifying `dot@branch` rather than just `dot` when specifying the dot name.

The following commands:
```bash
dm commit -m "A"
dm commit -m "B"
dm checkout -b newbranch
dm commit -m "C"
dm checkout master
dm commit -m "D"
dm checkout newbranch
dm commit -m "E"
```

Would create the following dot structure:


## Pushing

TODO introduce the hub.

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
