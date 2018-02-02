+++
draft = false
title = "Subdots on Docker"
synopsis = "Capturing multiple stateful components in a single commit"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

In Dotmesh, operations like commits and branches operate on [*dots*](/concepts/what-is-a-datadot/),
but each dot can contain multiple volumes you can mount into your
containers - and we call those [*subdots*](/concepts/what-is-a-datadot/#subdots).

This tutorial will explore how to use subdots to help manage the
stateful components of an app. We're basing the tutorial on a
fictitious app that is left to your imagination, but you can follow
along with the examples in a real Dotmesh installation.

## Getting Started.

Imagine you have an amazing application that uses MySQL to stores its
data, backed by a dot. Your `docker-compose.yaml` file contains something
like this:

```yaml
version: '3'
services:
  catalog-db:
    image: mysql:5.6.39
    environment:
     - MYSQL_ROOT_PASSWORD=secret
    hostname: catalog-db
    volumes:
     - myapp:/var/lib/mysql

volumes:
  myapp:
    driver: dm
```

...in addition to some containers that hold your actual app, but let's
leave those to the imagination for this tutorial!

Triumphantly, we deploy our app into production:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose up -d</kbd>
</pre></div>

## Gaining a second stateful container.

Life is good, but after six months, the investors start asking if
you're going to show any revenue this year and you decided you need to
actually start handling orders. The best way to add order handling to
your app is going to be using Mongo, so you add a Mongo container and
a new volume to your YAML.

Your order processing feature gets developed, goes into production,
and starts earning you revenue. Hooray!

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose down</kbd>
</pre></div>

```yaml
version: '3'
services:
  orders-db:
    image: mongo:3.4.10
    hostname: orders-db
    volumes:
     - myapp-orders:/data/db
  catalog-db:
    image: mysql:5.6.39
    environment:
     - MYSQL_ROOT_PASSWORD=secret
    hostname: catalog-db
    volumes:
     - myapp:/var/lib/mysql

volumes:
  myapp-orders:
    driver: dm
  myapp:
    driver: dm
```

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose up -d</kbd>
</pre></div>

But your devops team are starting to grumble that they now have to
remember to commit and push both the `default_myapp` and
`default_myapp-orders` dots for the hourly snapshot. Indeed, Bob, who
set up the production backup system didn't know the developers had
added a new stateful container at all for the first few weeks, and so
only the MySQL database was getting hourly snapshots at all!

And outside of production, all the scripts that drive the CI
processes, spinning up new environments for new developers, and all
that day to day routine, now have to have an extra line in them to
handle the `default_myapp-orders` dot as well as `default_myapp`. And,
perhaps worst of all, you have a niggling aching feeling that calling
your MySQL volume `myapp` in the first place was a mistake; it should
have been `myapp-catalog` - but at the time, it was just The Database
and that was that...

## Enter Subdots.

Belatedly, you remember reading about subdots in the Dotmesh manual
ages ago, and thinking "Hmmm, I'll be sure to remember that when my
app gets a bit more complex". Clearly, the two databases should be
subdots of a single `default_myapp` dot that, as the name suggests,
stores the state of your app.

The orders database only stores orders currently being processed, so
it's not very large. With a simple change to the YAML, you configure
the Mongo container to stores its data in an `orders-db` subdot of the
exist `default_myapp` dot:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose down</kbd>
</pre></div>

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
     - myapp:/var/lib/mysql

volumes:
  myapp.orders-db:
    driver: dm
  myapp:
    driver: dm
```

You transfer your existing Mongo database from the
`default_myapp-orders` dot into `default_myapp.orders-db`:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker run -v default_myapp-orders:/from -v default_myapp.orders-db:/to --volume-driver dm busybox sh -c 'cp -r /from/* /to'</kbd>
</pre></div>

And then you bring Mongo back up again, and your app's state is now
all in a single dot. You can delete the old `default_myapp-orders` dot
once you're confident everything is working fine:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm dot delete default_myapp-orders</kbd>
Please confirm that you really want to delete the dot default_myapp-orders, including all branches and commits? (enter Y to continue): <kbd>Y</kbd>
</pre></div>


<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose up -d</kbd>
</pre></div>

Now, all your backup, deployment, CI, testing, and developer
onboarding infrastructure can just deal with a single dot, `myapp`,
and all the subdots will tag along for the ride automatically. You
don't need to change your infrastructure or inform various teams if
your add needs a new database container.

But your setup is still a little... ugly. The Mongo orders database is
in a subdot, but the MySQL catalog database isn't. Or so it seems - if
you don't specify a subdot name, Dotmesh will just use the default
subdot, `__default__`. So it's easy to fix this!

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose down</kbd>
</pre></div>

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

You don't need to transfer the (massive) MySQL database across,
though; its old and new homes are still in the same dot, just
different subdots. You can use docker to mount the *root* of the dot
and rename the subdot:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker run -v default_myapp.__root__:/data --volume-driver dm busybox mv /data/__default__ /data/catalog-db</kbd>
</pre></div>

With that done, you can bring the system back up again:

<div class="highlight"><pre class="chromaManual">
$ <kbd>docker-compose up -d</kbd>
</pre></div>

And everything looks nice and neat:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm list</kbd>
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT            BRANCH  SERVER            CONTAINERS                                  SIZE        COMMITS  DIRTY
  default_myapp  master  f67d6806aac60301  /default_orders-db_1,/default_catalog-db_1  315.77 MiB  0        315.77 MiB  
$ <kbd>docker run -v default_myapp.__root__:/data --volume-driver dm busybox sh -c 'du -sk /data/*'</kbd>
118139	/data/catalog-db
205228	/data/orders-db
</pre></div>
