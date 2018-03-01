+++
draft = false
title = "1. Hello Dotmesh on Docker"
synopsis = "Getting Started with Dotmesh on Docker"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* [Docker Compose](https://docs.docker.com/compose/install/) if it didn't come with your Docker.
* Or try this example on our [hosted tutorial](/install-setup/katacoda/).
{{% /overview %}}

## Clone the app

The moby counter app is a very basic drawing app: it allows you to click to put logos on the screen.
The location of the logos is persisted to a Redis database.

First, clone the app repo from gihub.

{{< copyable name="step-01" >}}
git clone https://github.com/dotmesh-io/moby-counter
cd moby-counter
{{< /copyable >}}

The docker-compose file includes not only the app but also a request for a Docker volume from a dotmesh datadot.

Start the app.

{{< copyable name="step-02" >}}
docker-compose up -d
{{< /copyable >}}

You can see that the datadot referenced in the docker-compose file has been created.

{{< copyable name="step-03" >}}
dm list
{{< /copyable >}}

Make `moby_counter` the current datadot.

{{< copyable name="step-04" >}}
dm switch moby_counter
{{< /copyable >}}

This means that later `dm` commands will operate on that datadot, as indicated by the `*` in the list.

{{< copyable name="step-03" >}}
dm list
{{< /copyable >}}

```plain
  VOLUME       BRANCH  SERVER   CONTAINERS  SIZE       COMMITS  DIRTY
* moby_counter master  8f15abe  /moby       19.00 kiB  1        9.50 kiB
```

## Capture the empty state

Now, let's capture the empty state, run:

{{< copyable name="step-04" >}}
dm commit -m "Empty state"
{{< /copyable >}}

Now, load up the app in your browser at http://localhost:8100/ – you'll see an invitation to click on the screen. Before you do, let's make a new branch:

{{< copyable name="step-05" >}}
dm checkout -b branch_a
{{< /copyable >}}

## Draw an A on the screen

Now, draw an "A" on the screen! Then capture it:

{{< copyable name="step-06" >}}
dm commit -m "A on the screen"
{{< /copyable >}}

Note that if you go back to the master branch, the app updates automatically and you go back to your empty state:

{{< copyable name="step-07" >}}
dm checkout master
{{< /copyable >}}

Let's go back to the A state, as next we'll push it to the dothub.

{{< copyable name="step-08" >}}
dm checkout branch_a
{{< /copyable >}}

## Push "A state" to the dothub

At this point, try pushing your branch to [Dothub](https://dothub.com).

Start by registering for an account by clicking the link above.

Then back here, we'll set an environment variable with your Dothub username in it:

```plain
export HUB_USERNAME=<username>
```

Then add the hub as a remote:

{{< copyable name="step-09" >}}
dm remote add hub ${HUB_USERNAME}@dothub.com
{{< /copyable >}}

You will be prompted for your API key, which you can get from the [Settings/API Key page](https://dothub.com/ui/settings/apikey).

You can then push branches to the hub.

{{< copyable name="step-10" >}}
dm push hub moby_counter branch_a
{{< /copyable >}}

Then, go to Dothub and you should be able to see the volume, its branches and commits.


## Optional: Adding a collaborator

Prove that data can move between machines by inviting a friend or co-worker to join the [Dothub](https://dothub.com/) too!

When they've signed up, add them as a collaborator, by going to the _Settings_ page for your datadot, and type their user's username to add them as a collaborator.

Finally, send them a link to the following section so that they can clone your datadot and then you can finish the tutorial together!


### Instructions for your co-worker

So you been invited to pull down someone else's datadot?
Great, let's do it!

First, sign up for an account on the [Dothub](https://dothub.com).

Then tell the person who sent you here to add you as a collaborator to their dot.

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* [Docker Compose](https://docs.docker.com/compose/install/) if it didn't come with your Docker.
{{% /overview %}}

Next, let's set up some environment variables.

```plain
export DOT_OWNER=<their-username>
export COLLABORATOR=<your-username>
```

Authenticate to the hub:

{{< copyable name="step-12" >}}
dm remote add hub ${COLLABORATOR}@dothub.com
{{< /copyable >}}

You will be prompted for your API key, which you can get from the [Settings/API Key page](https://dothub.com/ui/settings/apikey).

Clone the repo locally

{{< copyable name="step-13" >}}
git clone https://github.com/datamesh-io/moby-counter
cd moby-counter
{{< /copyable >}}

Clone and switch to the dot before you start the app:

{{< copyable name="step-14" >}}
dm clone hub ${DOT_OWNER}/moby_counter
{{< /copyable >}}

Make `moby_counter` the current datadot.

{{< copyable name="step-15" >}}
dm switch moby_counter
{{< /copyable >}}

This means that later `dm` commands will operate on that datadot, as indicated by the `*` in the list.

{{< copyable name="step-16" >}}
dm list
{{< /copyable >}}

Start the app:

{{< copyable name="step-17" >}}
docker-compose up -d
{{< /copyable >}}

Pull and checkout the branch your co-worker created earlier:

{{< copyable name="step-18" >}}
dm pull hub moby_counter branch_a
dm checkout branch_a
{{< /copyable >}}

Now navigate to http://localhost:8100/ and you should see the same data that your coworker created running locally!

## What's next?

Try a more advanced version of the app with multiple microservices and polyglot persistence, and start building up a set of interesting states for your team in:

* [Using Dotmesh as a Library](/tutorials/library/).
