+++
draft = false
title = "2. Using Dotmesh as a Library"
synopsis = "Store development states of an app with polyglot persistence in a library."
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

In this tutorial, we'll show how to use dotmesh to capture a library of states so that you can avoid excess clicking and easily capture, organize and share interesting states.

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* Or try this example on our [hosted demo](/install-setup/katacoda/).
{{% /overview %}}

## The app

We'll use a modified version of the "moby counter" demo app we used in [Hello Dotmesh on Docker](/tutorials/hello-dotmesh-docker/).

The moby counter app allows you to click to put logos on the screen.
The location of the logos is persisted to the `clicks-db` database, which is a Redis database.

The modified version is on the [multiple-services](https://github.com/dotmesh-io/moby-counter/tree/multiple-services) branch of the repo.

## The new users service

This new version of the app has another microservice in addition to the original Node.js [web](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/server.js) service.

The new [users service](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/users/main.go) is written in Golang and, together with some changes to the frontend, provides two new features:

1. Users can now register by entering a username in the text field.
   There is no authentication yet -- users can just sign up by logging in for the first time.
   User information is stored in the `users-db` database, which is a PostgreSQL database.
   In particular, an auto-incrementing `user_id` is automatically generated for each new user.
2. Once users are logged in, they can _customize their experience_ -- they can upload a different image to put on the screen when they click.
   These images are stored on a plain filesystem.

Now we have more than one piece of state, we can show how Dotmesh is valuable with microservices.
In particular, it demonstrates Dotmesh's support for _polyglot persistence_: multiple types of databases and file stores in a single app made of multiple microservices.

## Using subdots to support polyglot persistence

<img src="/hugo/library-01-one-does-not-simply.png" alt="one does not simply capture the state of three microservices at once (meme based on 'one does not simply walk into mordor' from the lord of the rings)" style="width: 80%;" />

_Actually, we can!_

Take a look at the [`docker-compose.yml`](https://github.com/dotmesh-io/moby-counter/blob/multiple-services/docker-compose.yml) file in this branch.

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

{{< copyable name="step-01" >}}
git clone git@github.com:dotmesh-io/moby-counter
cd moby-counter
git checkout multiple-services
{{< /copyable >}}

And start it up (requires [Dotmesh on Docker](/install-setup/docker/) and Docker Compose):

{{< copyable name="step-02" >}}
docker-compose up -d
{{< /copyable >}}

Notice now that there is a new dot:

{{< copyable name="step-03" >}}
dm list
{{< /copyable >}}

Why is it called `mobycounter_app`?

Docker Compose automatically prefixes the name of the folder that the compose file is in to volume names that it passes to dotmesh.

Dotmesh strips off everything after the `.` because it puts multiple subdots inside a single dot.

Make it the active dot.

{{< copyable name="step-03" >}}
dm switch mobycounter_app
{{< /copyable >}}

We're ready to start capturing states!

## Let's capture some states and make a library!

There are at least four interesting states we can capture with this app, one useful to avoid excess clicking, and three which represent problem states which need fixes in the code:

1. **Pagination.** A users database with more than 10 users in it, which will be useful for testing pagination in the admin panel (which doesn't exist yet).
2. **The bug bug.** A bizarre _actual bug_ that shows up sometimes when you click enough times in certain parts of the screen.
   You might manage to cause it but not know how you did it!
   That makes it hard to explain how to reproduce it.
3. **Aspect ratios.** A display bug with how uploaded images with tall aspect ratios look. This is probably one for the frontend team.
4. **Security vulerability.** The best one: a security vulnerability!
   You've figured out how an unprivileged user can set the _default image_ for _all new users_!
   Oh no!
   Better get a reproducer over to the security team ASAP.

Note that all of the states depend on the state of _more than one of the databases_!
Good thing we can capture more than one of them at a time.

### First, capture the empty state on the master branch

{{< copyable name="step-04" >}}
dm commit -m "Empty state"
{{< /copyable >}}

This way we can come back to the master branch each time we want to create a new state.

### Make sure you have the hub as a remote

Check the output of the following command to see if `hub` is listed as a remote.

{{< copyable name="step-04b" >}}
dm remote -v
{{< /copyable >}}

If it isn't, add it.
Set an environment variable with your Dothub username in it:

```plain
export HUB_USERNAME=<username>
```
{{< copyable name="step-09" >}}
dm remote add hub ${HUB_USERNAME}@dothub.com
{{< /copyable >}}

You will be prompted for your API key, which you can get from the [Settings/API Key page](https://dothub.com/ui/settings/apikey).


### Pagination: Big users database

{{< copyable name="step-05" >}}
dm checkout -b many-users
{{< /copyable >}}

Go to the app at [localhost:8100](http://localhost:8100) and sign up 11 times (just by putting a new username in the login field each time).
Sign out by just reloading the page (stripping `?user=` off the URL if necessary).

{{< copyable name="step-06" >}}
dm commit -m "Created user1...user11 in user databases."
{{< /copyable >}}

Wow, that was boring.
Wouldn't it be nice if neither you nor anyone else on the team ever had to do that ever again.

{{< copyable name="step-07" >}}
dm push hub mobycounter_app many-users
{{< /copyable >}}

Now you don't, you can just pull down this state next time you need to test pagination of users.

Switch back to master for the next one.

{{< copyable name="step-08" >}}
dm checkout master
{{< /copyable >}}


### The bug bug: Bizarre "actual bug"

{{< copyable name="step-09" >}}
dm checkout -b bug-bug
{{< /copyable >}}

Go to the app at [localhost:8100](http://localhost:8100) and click 5 times in the top 100px of the screen.
You should see a real bug show up.

Now, if you didn't know that it only happened in those specific circumstances, and you created the state by accident, and then a co-worker struggled to reproduce it, that would be pretty annoying!
Let's keep this valuable and weird state safe until we get a chance to debug it.

{{< copyable name="step-10" >}}
dm commit -m "Huh, a real bug shows up on the screen, wtf."
{{< /copyable >}}

{{< copyable name="step-11" >}}
dm push hub mobycounter_app bug-bug
{{< /copyable >}}

Maybe you'll get round to figuring this one out, or maybe a coworker will need to pick it up because you're on vacation and it's affecting one of your biggest customers.
Good thing it's stored in **dothub** so that whoever needs to reproduce the state will be able to pick it up whenever they need to.

Switch back to master for the next one.

{{< copyable name="step-12" >}}
dm checkout master
{{< /copyable >}}


### Aspect ratios: Display bug with tall images

{{< copyable name="step-13" >}}
dm checkout -b aspect-ratios
{{< /copyable >}}

Go to the app at [localhost:8100](http://localhost:8100) and register (log in) as a user called `fred`.
Now go and find an image file with a tall aspect ratio.
I recommend searching Google Images for a picture of the Eiffel Tower.

Upload it as that user's custom image.

{{< copyable name="step-14" >}}
dm commit -m "
    Log in as 'fred' to see that only the top half of the uploaded image
    will show up.
"
{{< /copyable >}}

{{< copyable name="step-15" >}}
dm push hub mobycounter_app aspect-ratios
{{< /copyable >}}

Now you can send this off to the frontend team to sort out.

Switch back to master for the next one.

{{< copyable name="step-16" >}}
dm checkout master
{{< /copyable >}}


### Security vulnerability: Attacker can set default image

{{< copyable name="step-13" >}}
dm checkout -b security-vulnerability
{{< /copyable >}}

Go to the app at [localhost:8100](http://localhost:8100) and register (log in) as a user with an _empty string username_.
Now go and find a scary looking image that's the sort of thing a hacker would use to deface your app.
I recommend searching Google Images for a pirate flag.

Upload it as that user's custom image.

Observe that upon logging out (refreshing) and then creating a _new_ user, say `georgina`, that Georgina's account will now appear to be compromised, and will show the pirate flag when it should show the dotmesh logo as the default image (before she's uploaded anything)!

{{< copyable name="step-14" >}}
dm commit -m "
   Eek - register as any new user (e.g. 'newuser1') to see
   that all new accounts are showing a compromised image.
"
{{< /copyable >}}

{{< copyable name="step-15" >}}
dm push hub mobycounter_app security-vulnerability
{{< /copyable >}}

Now you can send this off to the security team to sort out.
Let's hope they write an acceptance test to catch this unexpected interaction and make sure it never comes back!

{{< copyable name="step-16" >}}
dm checkout master
{{< /copyable >}}

## Library created

OK, so you've created four branches and pushed them all to **dothub**.

What now?
You might want to open some issues for the bugs in your issue tracker.

In the issue tracker, you can link to the specific branch in the **dothub**, along with the specific branch of the code (`multiple-services`) that are needed _together_ to reproduce the issue.

So for example, for the security issue, you might write up the issue as:
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

**Being able to pin specific versions of data + code and run them together anywhere is what makes this workflow so powerful.**

It means that when someone else, potentially on a different team, certainly on a different computer, quite possibly on the other side of the planet, comes along to try and fix the bug, they'll be able to pull down and have the reproducer right there in front of them.

_NB: in the example above, it would be better if the URLs linked to did pin specific commits, rather than just referring to branches where the latest commits can change over time._

## What next?

OK, so you've filed all your issues.
What next?

Next up, let's pretend to be one of the developers who has to fix one of the bugs that we've captured in the library.

* [Collaborating with dotmesh and dothub](/tutorials/collaboration/).
