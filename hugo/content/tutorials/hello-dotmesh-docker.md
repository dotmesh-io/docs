+++
draft = false
title = "Hello Dotmesh on Docker"
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
* Or try this example on our [hosted demo](/install-setup/katacoda/).
{{% /overview %}}

## Clone the demo app

```plain
git clone https://github.com/datamesh-io/moby-counter
cd moby-counter
docker-compose up -d
```

You should then see:
```plain
dm list
```
```plain
  VOLUME       BRANCH  SERVER   CONTAINERS  SIZE       COMMITS  DIRTY
* moby_counter master  8f15abe  /moby       19.00 kiB  1        9.50 kiB
```

# Capture the empty state

Now, let's quickly capture the empty state, run:
```plain
dm switch moby_counter
dm commit -m "Empty state"
```

Now, load up the app in your browser at http://localhost:8100/ – you'll see an invitation to click on the screen. Before you do, let's make a new branch:
```plain
dm checkout -b branch_a
```

# Draw an A on the screen

Now, draw an "A" on the screen! Then capture it:
```plain
dm commit -m "A on the screen"
```

At this point, try pushing your branch to [Dothub](https://dothub.com).
Register there, and follow the in-app instruction to add a remote, e.g.:

```plain
dm remote add hub <yourusername>@dothub.com
```
You will be prompted for your API key, which is just the password you selected when you signed up. (FIXME, document how to get the API key)

You can then push branches to the hub. Push defaults to the current branch of the current volume (indicated with a `*` in the output of `dm list` and `dm branch` respectively), so you can just do:

```plain
dm switch <volume>
dm checkout <branch>
dm push hub
```

Then, go to Dothub and you should be able to see the volume, its branches and commits. Then, add a collaborator, by going to the _Settings_ page for a volume, and type another user's username to add them as a collaborator. Finally, that user can then `clone` your volume like this:

```plain
dm remote add hub <their-username>@cloud.datamesh.io
dm clone hub <your-username>/<your-volume-name> [<your-branch-name>]
```

They can then clone the same Git repo and do `docker-compose up -d`, and they should then be able to see whatever picture you drew with moby counter.

# Video demo

{{< youtube WUJAkdTwAPA>}}

FIXME re-record the video
