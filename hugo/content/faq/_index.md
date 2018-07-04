+++
draft = false
title = "FAQ"
synopsis = "Frequently Asked Questions."
knowledgelevel = ""
date = 2017-12-19T15:02:07Z
weight = "6"
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

## How does Dotmesh differ from dat?

The dat project is a decentralized network for sharing files while Dotmesh treats multiple databases (mysql, postgres, redis etc) in cloud-native (docker, kubernetes) apps like a git repo. So, Dotmesh is a database snapshotting tool with the added bonus that it can capture multiple databases in a single atomic commit.

## How does Dotmesh differ from Portworx?

Portworx and Dotmesh are really tackling different problems. We believe that Portworx is tackling storage for containers in production, with synchronously replicated block storage, the adoption of which will typically be an operations decision. This is great and it's a necessary component for many customers, especially on-prem where you don't have technology like EBS or GCE PD available (or where that technology is lacking).

Dotmesh on the other hand is tackling data management for cloud native apps – and it's starting with a developer tools focus. Our vision is to be able to capture, organize and share application states, i.e. snapshots of entire applications. Entire cloud native apps are often made up out of many microservices with polyglot persistence – that is, several of your microservices have their own databases. We solve that by each datadot (the unit that dotmesh operates on) being capable of hosting multiple databases for different microservices in [subdots](/concepts/what-is-a-datadot/#subdots), and then being able to treat the entire datadot like a git repo: where you can commit, branch, push and pull it.

Rather than trying to build another synchronously replicated block storage system, we're tackling the broader, more workflow-focused problem of getting the data you need to the right place throughout the software development lifecycle. 

## How does dotmesh differ from Rook?

We see Rook in the same category as Portworx, it's storage for containers in production. We believe new storage and data management tech should be built assuming public cloud first – and so it needs to make sense to run it on top of an EBS or a GCE PD.


## What is DotOps?

DotOps describes the new workflows that are enabled by using Dotmesh in your software development lifecycle, such as sharing dots with colleagues to debug problem states, or pushing dots from CI when a test fails.

DotOps is complementary with [GitOps](https://www.weave.works/blog/gitops-operations-by-pull-request).

## What do you encrypt?

We encrypt your password (but not your API keys) in the Dothub using [scrypt](https://godoc.org/golang.org/x/crypto/scrypt).
We encrypt data pushed to and pulled from the Dothub using TLS.

Currently, we do not encrypt pushes and pulls between OSS clusters, but it's on the roadmap.

We do not currently encrypt your volumes on disk.

Please [open an issue](https://github.com/dotmesh-io/dotmesh/issues/new) or give us feedback on Slack if you're interested in these features!

## What is the Circle of Control?

It's a concept borrowed from Stephen Covey's book [The Seven Habits
of Highly Effective
People](https://en.wikipedia.org/wiki/The_7_Habits_of_Highly_Effective_People). In
essence it means things that are inside the boundary of what you can
control. In software, and specifically when talking about dotmesh we
are referring to creating immutability as a form of control. For
example, version control and software testing lets you tame your
code. Immutable infrastructure lets you control your cloud resources,
but until now data has been outside the circle of control. Dotmesh
helps you to get a handle on your application state by snapshotting it
to give you immutable data and sane working practices.

## Does dotmesh support clusters?

Yes. See the [setup and install guides](/install-setup/) for details.

## Can I control which elements of my application state are captured in a datadot?

Yes. You have to explicitly attach a volume to a datadot for it to be
part of it, using PersistentVolumeClaims bound to the `dotmesh`
StorageClass in Kubernetes, or the `dm` volume driver in Docker.

## What environments will dotmesh work in? / What are the requirements for using dotmesh?

See the [setup and install guides](/install-setup/) for details on
dotmesh's platform requirements in different configurations.

## Do I have to use dothub or can I use another back end?

You don't need to use dothub. You might not want to pay us money, or
the bandwidth costs of transferring data into and out of your network
might be excessive, or you might have regulatory requirements about
handing your data to third parties. We understand.

If you configure all your dotmesh nodes into a cluster, then your dots
will be available uniformly across that cluster. You don't need any
external places to store them, and you can use the automatic commit
replication to provide a backup.

You can also run multiple clusters and push/pull dots between them, by
adding other clusters as a "remote". Read the [command line
reference](/references/cli/) for instructions on how to do that.

Also, you can run your own instance of dothub. If you would like to
use dothub for your enterprise, please [contact
us](https://dotmesh.com/pricing/register-interest/).

## What databases and data sources can dotmesh capture?

Anything that can run in Docker or Kubernetes and store its state in a
volume mounted into the container filesystem! Dotmesh provides a
filesystem interface to datadots, so anything that stores its state in
a filesystem can store its state in a datadot.

##  Can I host my own instance of dothub?

If you would like to use dothub for your enterprise, please [contact
us](https://dotmesh.com/pricing/register-interest/).
