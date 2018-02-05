+++
draft = false
title = "3. Collaborating with Dotmesh"
synopsis = "Fixing bugs others have captured with dotmesh"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

In [the Library tutorial](/tutorials/library/) we created a library of states that were interesting for various reasons and pushed them to the hub.

In this tutorial, we clone the (code, data) pair that exhibited one of the bugs in particular, and fix it!

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* Or try this example on our [hosted demo](/install-setup/katacoda/).
{{% /overview %}}

## Run through the library tutorial

If you haven't done the library tutorial yet, then do that first -- at least the [security vulnerability](/tutorials/library/#security-vulnerability) task.
You'll need access to the state in your dothub account (either as an owner or a collaborator of a dot) before you can clone it.

In particular, we'll assume that you have a `mobycounter_app` dot in your **dothub** account with a a `security-vulnerability` branch that exibits the bug:

```plain
Security issue
--------------

A regular user managed to set the default image for all new users - by creating
a user account with an empty string username.

Reproducer here:
https://dothub.com/ui/lukemarsden/mobycounter_app/tree/security-vulnerability
+
https://github.com/dotmesh-io/moby-counter/tree/multiple-services

Register as any new user that doesn't exist in the data commit, e.g. newuser1,
and you'll see pirate flags.
```

## Use a fresh environment

If you've just finished the [the Library tutorial](/tutorials/library/), you'll still have the state locally.

Since the whole point of this tutorial is to demonstrate cloning that state to a different environment, you should either:
* Wipe your docker environment (e.g. reset your Docker for Mac to factory defaults if you can -- be careful, this will destroy all your local containers & volumes), or
* Use the [katacoda](https://dotmesh.com/try-dotmesh/) environment for a fresh, empty environment.

## Make sure Dotmesh is installed

If you just wiped your environment, be sure to go back and [install dotmesh](/install-setup/docker/).

## Be the backend developer!

OK, so put yourself in the shoes of the security team member who's picked up the ticket above.
Let's go fix this security issue!

NB: In this tutorial we'll assume that you're just _pretending_ that you're being the bug-fixer (state consumer), after also being the bug-reporter (state creator).
If you're actually sharing the state with another person, you'll need to give them **collaborator access** to your dot in the [dothub](https://dothub.com), by clicking on _Settings_ for a dot and then adding their username.
In that case, they should refer to your dot on the dothub as `<yourusername>/mobycounter_app` in the `dm clone` commands below, rather than just `mobycounter_app` as we do in the following text (which defaults to cloning from your own namespace). 

The first thing you need to do is to get the right version of the code.
Looking at the ticket above, you can see that you need to do that with:

```

```


