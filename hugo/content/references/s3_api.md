+++
draft = false
title = "S3 API Reference"
synopsis = "Use the S3 protocol with dotmesh"
knowledgelevel = "Expert"
date = 2018-08-16T15:36:00Z
weight = "2"
[menu]
  [menu.main]
    parent = "references"
+++
# Overview
In addition to the RPC API we provide a limited S3-compatible API. This is available at `/s3` and the supported commands are explained below.

## Authentication
Our version of the S3 api uses basic authentication, which should be your username and password and can be supplied to curl using `-u <username>:<password>`.

## Bucket naming convention
The convention for dot names -> s3 bucket naming is `<namespace>:<name>@<branch>` - if using master branch, you can just use `<namespace>:<name>`. For example, the URL to Alice's dot `apples` would be `<host>:<port>/s3/alice:apples`.

## Supported endpoints

* [PutObject](#putobject)

### PutObject
URL format: `<host>:<password>/s3/<namespace>:<name>/<object-key>`
Putting objects is used for uploading or changing files. The following example creates a dot, creates a file then puts the file into the dot using s3:
```bash
dm init alice/apples
echo "hello, world" > hello-world.txt
curl -T hello-world.txt -u alice:notmypassword 127.0.0.1:32607/s3/alice:apples/hello-world.txt
```
This will result in a commit indicating the filename created or updated:
```bash
$ dm log
commit e5041af1-6f5a-4390-6689-5148d336bce4
author: 
date: 1534429919723622772

    saving file put by s3 api hello-world.txt
```

And the file will be written with the filename `hello-world.txt` which was supplied as the key.