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
You'll need the state in your dothub account (either as an owner or a collaborator of a dot) before you can clone it.

In particular, we'll assume that you have a `mobycounter_app` dot in your **dothub** account with a a `security-vulnerability` branch that exibits the bug:

```plain
Security issue
--------------

A regular user somehow managed to set the default image for all new users.

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

<!-- TODO: add `dm cluster reset` as an option here only after https://github.com/dotmesh-io/dotmesh/issues/248 and https://github.com/dotmesh-io/dotmesh/issues/66 are fixed -->
<!-- TODO: add `dm dot delete` as an option here only after https://github.com/dotmesh-io/dotmesh/issues/242 has been fixed -->

## Make sure Dotmesh is installed

If you just wiped your environment, be sure to go back and [install dotmesh](/install-setup/docker/).

## Be the backend developer!

OK, so put yourself in the shoes of the security team member who's picked up the ticket above.
Let's go fix this security issue!

NB: In this tutorial we'll assume that you're just _pretending_ that you're being the bug-fixer (state consumer), after also being the bug-reporter (state creator).
If you're actually sharing the state with another person, you'll need to give them **collaborator access** to your dot in the [dothub](https://dothub.com), by clicking on _Settings_ for a dot and then adding their username.
In that case, they should refer to your dot on the dothub as `<yourusername>/mobycounter_app` in the `dm clone` commands below, rather than just `mobycounter_app` as we do in the following text (which defaults to cloning from your own namespace in the dothub). 

## Get the right version of the data and the right version of the code to reproduce the vulnerability

The first thing you need to do is to get the right version of the code.
Looking at the ticket above, you can see that you need to do that with:

{{< copyable name="step-01" >}}
git clone https://github.com/dotmesh-io/moby-counter
cd moby-counter
git checkout multiple-services
{{< /copyable >}}

Now, before starting up the app, let's get the right version of the data!

Make sure you have a remote setup for [dothub.com](dothub.com).


{{< copyable name="step-01" >}}
dm remote -v | grep dothub.com
{{< /copyable >}}


If you need to add the dothub remote, you can follow the [setup docs](/tutorials/library/#make-sure-you-have-the-hub-as-a-remote)

Clone the datadot:

{{< copyable name="step-02" >}}
dm clone hub mobycounter_app
dm switch mobycounter_app
{{< /copyable >}}

Now that we've cloned the datadot, we can start up the app:

{{< copyable name="step-03" >}}
docker-compose up -d --build
{{< /copyable >}}

And then finally pull down and switch to the specific branch which has the data we need to reproduce the problem:

{{< copyable name="step-04" >}}
dm pull hub mobycounter_app security-vulnerability
dm checkout security-vulnerability
{{< /copyable >}}

## Inspect the state to find clues and form a hypothesis

Now go to [http://localhost:8100](http://localhost:8100) to observe the exploited state of the app.

Register as a new user and observe that indeed, the pirate flag (or whatever image you uploaded in the [library tutorial](/tutorials/library) does show up.

Now that you have the reproducer locally, we can immediately start inspecting the state, and once we've found some clues, and formed a hypothesis, we can start changing the code in the users service -- adding `print` statements, and so on, to confirm our hypothesis and then -- hopefully -- fix the problem.

Let's start by taking a look at the state of the datadot:

{{< copyable name="step-05" >}}
docker run -ti -v mobycounter_app.__root__:/dot --volume-driver dm \
    bash ls -alh /dot
{{< /copyable >}}

Here we can see all the subdots, because we mounted the special name `__root__` which mounts the root of the dot.
Subdots are just directories inside the dot.
Let's look inside the "uploads" subdot:

{{< copyable name="step-06" >}}
docker run -ti -v mobycounter_app.__root__:/dot --volume-driver dm \
    bash ls -alh /dot/uploads
{{< /copyable >}}

OK, interesting.
There's a `default.png` here that looks different to the one shipped with the code:

{{< copyable name="step-07" >}}
md5sum users/default.png
docker run -ti -v mobycounter_app.__root__:/dot --volume-driver dm \
    bash md5sum /dot/uploads/default.png
{{< /copyable >}}

## Clue #1: the default image got overwritten

The hashes don't match!
How did the default image get overwritten?

## Dotmesh just reduced our "mean time to clue"

Now let's go and inspect the users database, and see what's going on there.

{{< copyable name="step-08" >}}
docker run -ti --net=mobycounter_default --rm jbergknoff/postgresql-client \
    postgresql://postgres:secret@users-db:5432/postgres
{{< /copyable >}}

At the `pgsql>` prompt:

{{< copyable name="step-09" >}}
SELECT * FROM users;
{{< /copyable >}}

```plain
 id | username
----+----------
  1 |
 34 | sdsd
(2 rows)
```

A-ha! There is a user with an empty username!

(tip: `\q` to quit psql)

## Clue #2: an empty-string username

So we might be starting to see what's going on here now.
There was an empty-string username in the response.

**Hypothesis:** an empty string username allows an attacker to overwrite the default image for all new users.

Let's go and test our hypothesis by enabling some logging to the users service by activating the following code we conviniently placed for this exercise:

```golang
func SetImageForUser(w http.ResponseWriter, r *http.Request) {

    /* ... */

    if os.Getenv("DEBUG") != "" {
      log.Printf(
        "[SetImageForUser] using image filename %v for user name=%v id=%v",
        username, userId,
      )
    }

    /* ... */

}
```

It will enable us to log the users container and see what is happening when we upload an image as a user.


## Test the hypothesis

Let's activate the logging feature by restarting the users container exporting the `DEBUG` variable in the meantime:

{{< copyable name="step-10" >}}
docker-compose stop users
export DEBUG=1
docker-compose up -d users
{{< /copyable >}}

Now go to the app at [http://localhost:8100](http://localhost:8100) and log in without putting anything in the text box.
Then upload a new image, and check the users service docker logs:

{{< copyable name="step-11" >}}
docker-compose logs -f users
{{< /copyable >}}

```plain
Attaching to mobycounter_users_1
users_1     | 2018/02/08 19:14:10 Initialized users table if it didn't exist.
users_1     | 2018/02/08 19:14:41 [SetImageForUser] using image filename  for user name=1 id=%!v(MISSING)
```

A-ha, yes indeed!
So, now we:

* can reproduce the problem
* understand what's causing it

Fixing the code is now the easy bit!
And writing a test should be straightforward too.

## Exercises for the reader

1. Fix the code.
2. Write an end-to-end test that proves that the problem is fixed.

Feel free to do these the other way round if you're a fan of test-driven development.

Bonus points for finding the other, related bug.

## What's next?

As part of fixing this problem, we'll want to _write an end-to-end (a.k.a. acceptance or integration) test to ensure that the problem doesn't come back_.

What happens if that test starts failing in the future?

Is there a way to make the CI system automatically push the failed state to the dothub?
This means that reproducing the failure and minimizing *mean time to clue* next time will be as easy as it was above when someone gave us a manually-created reproducer in a datadot?

## Check out these tutorials

* [Capture failed CI runs in Travis](/tutorials/capture-failed-ci-runs-travis/)
* [Capture failed CI runs in Jenkins](/tutorials/capture-failed-ci-runs-jenkins/)
* [CI with GitLab and Kubernetes](/tutorials/ci-gitlab-kubernetes/)
