+++
draft = false
title = " What is a Datadot"
synopsis = "Datadots, commits, subdots, branches, pushing & pulling."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "concepts"
+++

_Want to try the examples here without [installing Dotmesh](/install-setup)?_
_Try running the commands in our [online learning environment](/install-setup/katacoda)._

## Datadots

A Datadot allows you to capture your application's state and treat it like a `git` repo.

A simple example is to start a PostgreSQL container using a Datadot called `myapp`:

```bash
docker run -d --volume-driver dm \
    -v myapp:/var/lib/postgresql/data --name postgres postgres:9.6.6
```

This creates a datadot called `myapp`, creates the writeable filesystem for the default `master` branch in that datadot, mounts the writeable filesystem for the `master` branch into `/var/lib/postgresql/data` in the `postgres` container, and starts the `postgres` container, like this:

<img src="/hugo/what-is-a-datadot-01-myapp-dot.png" alt="myapp dot with master branch and postgres container's /data volume attached" style="width: 80%;" />

First, switch to it, which, like `cd`'ing into a git repo, makes it the "current" dot -- the dot which later `dm` commands will operate on by default:

```bash
dm switch myapp
```

You can then see the `dm list` output:

```bash
dm list
```

```plain
  DOT      BRANCH  SERVER   CONTAINERS  SIZE       COMMITS  DIRTY
* myapp    master  a1b2c3d  /postgres   40.82 MiB  0        40.82 MiB
```
The current branch is shown in the `BRANCH` column and the current dot is marked with a `*` in the `dm list` output.

For more information on what all of the columns mean, see the [CLI Reference](/references/cli/).

## Commits

You can commit a datadot by running:

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
commit 7f8c7cb6-c925-44b4-5a65-bcbf05a1da39
Author: admin
Date: 1517055060834886217

    empty state

commit 435a520f-d01e-4bda-70e0-fc42e2043634
Author: admin
Date: 1517055069443640226

    some data
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

A datadot should be named after your application: `myapp2`.

Assume that your app has an `orders` service with an `orders-db`, and a `catalog` service with a `catalog-db`.

In this case, good names for your subdots would be `myapp.orders-db` and `myapp.catalog-db`.

The `.` character is used to separated the dot name from the subdot name.

Example Docker Compose syntax would be:

```yaml
version: '3'
services:
  orders-db:
    image: mongo:3.4.10
    hostname: orders-db
    volumes:
     - myapp.orders-db:/data/db
  catalog-db:
    image: mysql:5.6.39
    environment:
     - MYSQL_ROOT_PASSWORD=secret
    hostname: catalog-db
    volumes:
     - myapp.catalog-db:/var/lib/mysql

volumes:
  myapp.orders-db:
    driver: dm
  myapp.catalog-db:
    driver: dm
```

See also: [Docker Compose integration](TODO).

Starting the above Docker Compose file would create a dot with the following structure:

<img src="/hugo/what-is-a-datadot-03-myapp-subdots.png" alt="a dot with an orders-db and catalog-db subdots" style="width: 80%;" />

You can think of subdots as different "partitions" of the master branch's writeable filesystem, in the sense that they divide it up, so that different containers can use different independent parts of it.

Commits and branches of a datadot apply to the _entire_ datadot, not specific subdots.
This means that your datadot commits can represent snapshots of the state of your _entire application_, not the individual data services, like this:

```bash
dm switch myapp
dm commit -m "two empty dbs"
```

Then some data is written to both databases by the app, then you can capture them together atomically:

```bash
dm commit -m "data in two dbs"
```

The resulting dot structure is:

<img src="/hugo/what-is-a-datadot-04-myapp-subdots-with-commits.png" alt="a dot with an orders-db and catalog-db subdots showing two commits which capture the entire dot, not the individual subdot - so the commits are of multiple databases simultaneously" style="width: 80%;" />

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

If you want to disable this behavior, you can pin a branch for a mount by specifying `dot@branch` rather than just `dot` when specifying the dot name.

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

<img src="/hugo/what-is-a-datadot-05-myapp-branches.png" alt="a dot with commits A and B on master, a branch newbranch from B going to C and E, and a later commit (on the other side of the fork) D on master. two writeable filesystems, and the postgres container using the writeable filesystem of newbranch" style="width: 80%;" />

Note that the postgres container in this example is using the writeable filesystem of `newbranch` -- that is because at the end of the commands `newbranch` was the current branch, the latest one that was checked out.
Running a further `dm checkout master` would switch the `postgres` container over to the `master` branch.

Branches work just fine with subdots too:

<img src="/hugo/what-is-a-datadot-06-myapp-branches-with-subdots.png" alt="the same branching structure as above, but this time with subdots - each writeable filesystem and commit now has two databases in it" style="width: 80%;" />

In which case each writeable filesystem and each commit just has multiple data stores in it.


## Pushing

You can get more out of dotmesh by sharing your dots with others -- either other users, or systems like a CI system.
In order to facilitate this sharing, you can push the commits on a branch to a hub.

You can either use [our hub](https://dothub.com) or you can just install dotmesh on a server and use that.

If your username is `alice` and you want to make commit `E` on `newbranch` from the example above available to others, first log into the hub:

```bash
dm remote add hub alice@dothub.com
```

Then push the branch to the hub:

```bash
dm push hub myapp newbranch
```

This will push all the commits (including commits on branches that a non-master branch depends on) necessary to get the latest commit on `newbranch` up to the hub:

<img src="/hugo/what-is-a-datadot-07-myapp-pushing.png" alt="pushing newbranch to a hub, showing that commits A, B, C and E are transferred to the hub" style="width: 100%;" />

B is the base commit for branch newbranch, so, first the commits on the master branch up to and including B are pushed, then commits C and E are transferred to get the hub up to date with the latest commit on `newbranch`.


## Cloning & pulling

The opposite of pushing is cloning & pushing.
Cloning is for the first time you pull down a dot.
Pulling is for updating it later with more commits.

If you, `bob`, have collaborator access to a colleague `alice`'s dot `myapp`, you can clone it with:

```bash
dm clone hub alice/myapp newbranch
```

Later, if `pete` pushes new commits, you can pull them into your local `sockshop` dot with:

```bash
dm pull hub myapp
```

Note that when pulling, you give the local name `myapp`.
You can see how the default upstream dot is configured by running:

```bash
dm dot show myapp
```

For more details, see the [CLI reference](TODO: link to CLI reference).

## Further reading

* See also: [Hello Dotmesh Tutorial](/tutorials/hello-dotmesh-docker/)
* See also: [Docker Compose reference](/references/docker-compose/)
