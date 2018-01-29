+++
draft = false
title = "Dotmesh with MySQL"
synopsis = "A simple example using dotmesh with MySQL and the MySQL client"
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


## Run your first dotmesh enabled container

Start a MySQL container using a dot named `mydata` for the MySQL data directory.

```bash
docker run -d -v mydata:/var/lib/mysql \
    --volume-driver=dm --name=db \
    -e MYSQL_ROOT_PASSWORD=secret mysql:5.6.39
```

`dm switch` makes the new dot the current dot, which means the CLI operates on it, a bit like `cd`ing into a `git` working directory.

```plain
dm switch mydata
```

`dm list` shows you the `mydata` volume that was created on-demand, that it is current, and that the `db` container is using `mydata`'s default `master` branch.

```plain
dm list
```
```plain
Current remote: local (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT     BRANCH  SERVER            CONTAINERS  SIZE        COMMITS  DIRTY
* mydata  master  e21268d0e6df269c  /db         115.34 MiB  0        115.34 MiB
```

The `dm` CLI supports a subset of `git` syntax to operate on this volume, see `dm --help` and the [CLI command reference](/references/cli/) for more details.


## Commit and branch a datadot

Here we use the `dm` CLI to make a commit (snapshot) of our empty MySQL instance.

```plain
dm commit -m "No database"
```

Then we use a `mysql` client container to create a database and a table in our MySQL instance.

```plain
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret
```
At the `mysql>` prompt:
```plain
create database hello;
use hello;
create table countries (name varchar(255));
exit;
```

Then we make a commit to capture the schema:

```plain
dm commit -m "Created hello database and countries table"
```
Create a new branch based on the schema:
```plain
dm checkout -b newbranch
```
Insert some data into it:
```plain
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
```
At the `mysql>` prompt:
```plain
insert into countries set name="england";
```
```plain
Query OK, 1 row affected (0.01 sec)
```
```plain
exit;
```
And make a commit:
```plain
dm commit -m "Inserted england row"
```

Then we go back to the `master` branch and observe that the data has disappeared.

```plain
dm checkout master
```
```plain
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
```
At the `mysql>` prompt:
```plain
select * from countries;
```
```plain
Empty set (0.00 sec)
```

And we can switch back to `newbranch` and it will reappear.

```plain
dm checkout newbranch
```
```plain
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
```
At the `mysql>` prompt:
```plain
select * from countries;
```
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
```plain
dm log
```
To see the list of commits in any branch.

```plain
dm branch
```
To see which branch you're on now.

To see other commands you can run, check out the [CLI reference](/references/cli/).

## Push to a remote dotmesh

From one dotmesh, you can push branches and commits to another one after authenticating to it.

We run a public dotmesh cluster at `dothub.com`.

[Sign up for the public cluster](https://dothub.com) and then specify your username and API key as shown.

```plain
export DOTHUB_USER=<your-username>
```

```plain
dm remote -v
dm remote add hub ${DOTHUB_USER}@dothub.com
```

You will be asked for your API key, which you can get from TODO FIXME.
```plain
Please enter your API key:
Successfully connected to <your-username>@dothub.com
Remote added
```

You can now push the current branch of the current dot to the remote:

```plain
dm list
```
```plain
Current remote: default

  VOLUME   SERVER          BRANCH   CONTAINERS
* mydata   172.16.93.101   master   /db
```

```plain
dm push hub
```
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

```plain
dm clone origin ${DOTHUB_USER}/mydata newbranch
```
```plain
Pulling: [######            ] 3.7MB/sec, ETA 2 seconds
```

Then have them switch to the dot:
```plain
dm switch mydata
```
Start the MySQL server using it:
```plain
docker run -d -v mydata:/var/lib/mysql \
    --volume-driver=dm --name=db \
    -e MYSQL_ROOT_PASSWORD=secret mysql:5.6.39
```
Connect with the `mysql` client:
```plain
docker run --link db:db -ti mysql:5.6.39 \
    mysql -hdb -uroot -psecret hello
```
At the `mysql>` prompt:
```plain
select * from countries;
```
```plain
+----------+
| name     |
+----------+
| england  |
+----------+
1 row in set (0.00 sec)
```
