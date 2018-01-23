+++
draft = false
title = "What is a Datadot"
synopsis = "Datadots, commits, subdots, branches."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "concepts"
+++

## Datadots

A datadot is your application's state.

Create one by starting a docker compose file which includes your datadot:

```
git clone https://github.com/dotmesh-io/demos
cd demos/hello-dotmesh
docker-compose up -d
```


## Commits

Modern apps often have more than one database, cache or queue
A datadot can capture all of those states in a single, atomically consistent commit.

You can commit a datadot with:
```
dm commit -m "Bug 16637 reproducer: incorrect total calculations with zero-rated VAT items between EU countries"
```


## Subdots

A datadot might be named with your application:
* `sockshop`

That dot's subdots are named:
* `sockshop.orders-db`
* `sockshop.catalog-db`

And so on, for the different microservices in `sockshop`.


## Branches

Just like `git`, you can make a branch from a commit on a datadot.

```
dm checkout -b bug-16637
dm commit -m "[...]"
```


## Pushing

If you, `pete`, want to make your dot available to others, push it:

```
dm remote add hub pete@dothub.com
dm push sockshop hub
```


## Cloning & pulling

If you, `lukemarsden`, have collaborator access to a colleague `pete`'s dot `sockshop`, you can clone it with:

```
dm clone lukemarsden@dothub.com:pete/sockshop
```

Later, if `pete` pushes new commits, you can pull them into your local `sockshop` dot with:

```
dm pull hub sockshop
```
