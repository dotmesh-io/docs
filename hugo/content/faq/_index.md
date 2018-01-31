+++
draft = false
title = "FAQ"
synopsis = "Frequently Asked Questions."
knowledgelevel = ""
date = 2017-12-19T15:02:07Z
order = "6"
+++

## How does Dotmesh differ from Git?

Dotmesh borrows a lot of its concepts and language from Git, but there are some important differences:

* With the Docker and Kubernetes integrations, Datadots don't manifest directly on your filesystem.
  Instead, they are mounted into containers which aren't directly accessible via your normal CLI interactions.
  In `git`, you can switch between different repos by just using `cd` to switch between directories.
  This is why `dm` has [`dm switch`](/references/cli/#select-a-different-current-dot-dm-switch-dot), it's the equivalent of using `cd` to switch between `git` repos.
* Dotmesh has no staging area like `git`.
  This means that commits are one-stage (just commit) rather than two-stage (stage changes, then commit).
  The state of the writeable filesystem that each branch comes with is exactly what will be committed when you type `dm commit`.
  One practical upshot of this is that you'll often want to make a "empty state" commit before you start doing anything.
  This is because you won't get a chance to pick which changes you want to go into a commit.
* A branch cannot be rolled back to before its origin commit.
  Unlike `git`, you cannot roll a branch back to a commit from before it was started.

## What is DotOps?

DotOps describes the new workflows that are enabled by using Dotmesh in your software development lifecycle, such as sharing dots with colleagues to debug problem states, or pushing dots from CI when a test fails.

DotOps is complementary with [GitOps](https://www.weave.works/blog/gitops-operations-by-pull-request).

## What do you encrypt?

We encrypt your password (but not your API keys) in the Dothub using [scrypt](https://godoc.org/golang.org/x/crypto/scrypt).
We encrypt data pushed to and pulled from the Dothub using TLS.

Currently, we do not encrypt pushes and pulls between OSS clusters, but it's on the roadmap.

We do not currently encrypt your volumes on disk.

Please [open an issue](https://github.com/dotmesh-io/dotmesh/issues/new) or give us feedback on Slack if you're interested in these features!
