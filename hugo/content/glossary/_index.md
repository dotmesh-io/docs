+++
draft = false
title = "Glossary"
synopsis = "Names of Things."
knowledgelevel = ""
date = 2017-12-19T15:02:07Z
order = "7"
+++

* See also: [What is a Datadot](/concepts/what-is-a-datadot/) for a more detailed explanation of these topics with examples and diagrams.

## Mesh
A set of dotmesh clusters, spanning different data centers, laptops etc, with a hub (another dotmesh cluster) at the center (also the people and workflows around it).

## Cluster
A dotmesh cluster, one or more machines hosting a set of dots.

## Datadot
A way to organise, capture and share a collection of states that relate to an application (possibly including multiple data stores, and multi-instance data stores).
Like a git repo, it's a branchable, committable thing.
But unlike a git repo, it supports running real databases on top of it and can process large amounts of data efficiently.

## Branch
A writable filesystem that can be based on another branch's commit (or is the initially empty "master" branch).
Branches also have zero or more commits.
The analogy is to git branches.

## Commit
A point in time snapshot of a branch with a given hash/identifier.

## Subdot
"Partitions" of a dot which can be mounted into different containers and which can be committed together.

## Volume
The manifestation of a branch's writeable filesystem when it is e.g. mounted into a container.
