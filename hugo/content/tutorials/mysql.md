+++
draft = false
title = "Dotmesh with MySQL"
synopsis = "A simple example using dotmesh with MySQL and the MySQL client"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "8"
[menu]
  [menu.main]
    parent = "tutorials"
+++

{{% overview %}}
* [Dotmesh on Docker](/install-setup/docker/).
* Or try this example on our [hosted demo](/install-setup/katacoda/).
{{% /overview %}}


## Run a dotmesh enabled MySQL container

Start a MySQL container using a dot named `mydata` for the MySQL data directory.

{{< copyable name="step-01" >}}
docker run -d -v mydata:/var/lib/mysql \
    --volume-driver=dm --name=db \
    -e MYSQL_ROOT_PASSWORD=secret mysql:5.6.39
{{< /copyable >}}

`dm switch` makes the new dot the current dot, which means the CLI operates on it, a bit like `cd`ing into a `git` working directory.

{{< copyable name="step-02" >}}
dm switch mydata
{{< /copyable >}}

`dm list` shows you the `mydata` volume that was created on-demand, that it is current, and that the `db` container is using `mydata`'s default `master` branch.

{{< copyable name="step-03" >}}
dm list
{{< /copyable >}}
```plain
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT     BRANCH  SERVER            CONTAINERS  SIZE        COMMITS  DIRTY
* mydata  master  e21268d0e6df269c  /db         115.34 MiB  0        115.34 MiB
```

The `dm` CLI supports a subset of `git` syntax to operate on this volume, see `dm --help` and the [CLI command reference](/references/cli/) for more details.


## Commit and branch a datadot

Here we use the `dm` CLI to make a commit (snapshot) of our empty MySQL instance.

{{< copyable name="step-04" >}}
dm commit -m "No database"
{{< /copyable >}}

Then we use a `mysql` client container to create a database and a table in our MySQL instance.

{{< copyable name="step-05" >}}
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret
{{< /copyable >}}

At the `mysql>` prompt:

{{< copyable name="step-06" >}}
create database hello;
use hello;
create table countries (name varchar(255));
exit;
{{< /copyable >}}

Then we make a commit to capture the schema:

{{< copyable name="step-07" >}}
dm commit -m "Created hello database and countries table"
{{< /copyable >}}

Create a new branch based on the schema:

{{< copyable name="step-08" >}}
dm checkout -b newbranch
{{< /copyable >}}

Insert some data into it:
{{< copyable name="step-09" >}}
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
{{< /copyable >}}

At the `mysql>` prompt:

{{< copyable name="step-10" >}}
insert into countries set name="england";
{{< /copyable >}}
```plain
Query OK, 1 row affected (0.01 sec)
```
{{< copyable name="step-11" >}}
exit;
{{< /copyable >}}

And make a commit:

{{< copyable name="step-12" >}}
dm commit -m "Inserted england row"
{{< /copyable >}}

Then we go back to the `master` branch and observe that the data has disappeared.

{{< copyable name="step-13" >}}
dm checkout master
{{< /copyable >}}
{{< copyable name="step-14" >}}
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
{{< /copyable >}}

At the `mysql>` prompt:

{{< copyable name="step-15" >}}
select * from countries;
{{< /copyable >}}
```plain
Empty set (0.00 sec)
```

And we can switch back to `newbranch` and it will reappear.

{{< copyable name="step-16" >}}
dm checkout newbranch
{{< /copyable >}}
{{< copyable name="step-17" >}}
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
{{< /copyable >}}

At the `mysql>` prompt:

{{< copyable name="step-18" >}}
select * from countries;
{{< /copyable >}}
```plain
+----------+
| name     |
+----------+
| england  |
+----------+
1 row in set (0.00 sec)
```

In this way, we can create many branches for different states of the database.

Also try:
{{< copyable name="step-19" >}}
dm log
{{< /copyable >}}

To see the list of commits in any branch.

{{< copyable name="step-20" >}}
dm branch
{{< /copyable >}}

To see which branch you're on now.

To see other commands you can run, check out the [CLI reference](/references/cli/).

## Push to a remote dotmesh

From one dotmesh, you can push branches and commits to another one after authenticating to it.

We run a public dotmesh cluster at [https://dothub.com](https://dothub.com).

[Sign up for the public cluster](https://dothub.com) and then specify your username and API key as shown.

```plain
export DOTHUB_USER=<your-username>
```

{{< copyable name="step-21" >}}
dm remote -v
dm remote add hub ${DOTHUB_USER}@dothub.com
{{< /copyable >}}

You will be asked for your API key, which you can get from the [Settings/API Key page in the Hub](https://saas.dotmesh.io/ui/settings/apikey).
```plain
Please enter your API key:
Successfully connected to <your-username>@dothub.com
Remote added
```

You can now push the current branch of the current dot to the remote:

{{< copyable name="step-22" >}}
dm list
{{< /copyable >}}
```plain
Current remote: default

  VOLUME   SERVER          BRANCH   CONTAINERS
* mydata   172.16.93.101   master   /db
```

{{< copyable name="step-23" >}}
dm push hub
{{< /copyable >}}
```plain
Pushing: [######            ] 3.7MB/sec, ETA 2 seconds
```

You should see the dot appear in your [dothub account](https://dothub.com).


## Pull on another dotmesh
To prove to yourself that you can pull what you just pushed, install dotmesh on another computer (or ask a friend or colleague to install it), and then pull the branch down, run a MySQL container, and query the database again.
You should see the data there just as you left it when you committed on the first machine.

You will need to give your friend or colleague permission to collaborate on a dotmesh repo, you can do that through the web interface at [dothub.com](https://dothub.com).

Ask your friend to set an environment variable referring to your dothub username:
```plain
export DOTHUB_USER=<your-username>
```

{{< copyable name="step-24" >}}
dm clone origin ${DOTHUB_USER}/mydata newbranch
{{< /copyable >}}
```plain
Pulling: [######            ] 3.7MB/sec, ETA 2 seconds
```

Then have them switch to the dot:
{{< copyable name="step-25" >}}
dm switch mydata
{{< /copyable >}}

Start the MySQL server using it:

{{< copyable name="step-26" >}}
docker run -d -v mydata:/var/lib/mysql \
    --volume-driver=dm --name=db \
    -e MYSQL_ROOT_PASSWORD=secret mysql:5.6.39
{{< /copyable >}}

Connect with the `mysql` client:

{{< copyable name="step-27" >}}
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
{{< /copyable >}}

At the `mysql>` prompt:

{{< copyable name="step-28" >}}
select * from countries;
{{< /copyable >}}
```plain
+----------+
| name     |
+----------+
| england  |
+----------+
1 row in set (0.00 sec)
```

Congratulations, you just moved a MySQL snapshot from one computer to another, via the hub!
