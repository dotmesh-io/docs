+++
draft = false
title = "2. Using Dotmesh as a Library"
synopsis = "Store development states of an app with polyglot persistence in a library: to avoid excess clicking and capture problem states."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* Or try this example on our [hosted demo](/install-setup/katacoda/).
{{% /overview %}}

## The app

In this tutorial we'll use a modified version of the "moby counter" demo app we used in [Hello Dotmesh on Docker](/tutorials/hello-dotmesh-docker/).

The moby counter app allows you to click to put logos on the screen.
The location of the logos is persisted to the `clicks-db` database, which is a Redis database.

The modified version is on the [multiple-services](https://github.com/dotmesh-io/moby-counter/tree/multiple-services) branch of the repo.

The version on this branch has a new microservice, in addition to the original Node.js [web](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/server.js) service.

The new [users service](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/users/main.go) is written in Golang and, together with some changes to the frontend, provides two new features:

1. Users can now register by entering a username in the text field.
   There is no authentication yet - users can just sign up by logging in.
   User information is stored in the `users-db` database, which is a PostgreSQL database.
2. Once users are logged in, they can _customize their experience_ -- they can upload a different image to put on the screen when they click.
   These images are stored on a plain filesystem.
   In future they might get uploaded to S3 to allow the images service to scale better.

NB: It would also make sense to split the users service into a `users` service and an `images` service.
The code in this branch is meant to indicate a _progression towards microservices_.

It is realistic enough to provide a useful demonstration of how Dotmesh is valuable with microservices.
In particular, it demonstrates Dotmesh's support of _polyglot persistence_: multiple types of databases and file stores in a single app made of multiple microservices.

## Using subdots to support polyglot persistence

Take a look at the [`docker-compose.yml`](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/docker-compose.yml) file in this branch.

<img src="/hugo/library-01-one-does-not-simply.png" alt="one does not simply capture the state of three microservices at once (meme based on 'one does not simply walk into mordor' from the lord of the rings)" style="width: 80%;" />

_Yes we do!_

Note how it has _three_ stateful components (excerpt):

```yaml
volumes:
  app.clicks-db:
    driver: dm
  app.users-db:
    driver: dm
  app.uploads:
    driver: dm
```

These docker volumes reference three subdots of the same dotmesh dot: "app".
Note how they are then used in the `volumes` definitions of the various microservices.

Let's get our hands on the app:

{{< copyable name="step-1" >}}
git clone git@github.com:dotmesh-io/moby-counter
cd moby-counter
git checkout multiple-services
{{< /copyable >}}  

And start it up (requires [Dotmesh on Docker](/install-setup/docker/) and Docker Compose:

{{< copyable name="step-2" >}}
docker-compose up -d
{{< /copyable >}}  

Notice now that there is a new dot called `mobycounter_app`:

{{< copyable name="step-2" >}}
dm list
{{< /copyable >}}  

Why that name?
Docker Compose automatically prefixes the name of the folder that the compose file is in to volume names that it passes to dotmesh, and dotmesh strips off everything after the `.` because it puts _multiple subdots inside a single dot_.




