+++
draft = false
title = "Capture failed CI runs in Travis"
synopsis = "Save failed CI runs"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "5"
[menu]
  [menu.main]
    parent = "tutorials"
+++

# Travis
We are going to use Travis to capture the state of your CI at the end of a run.

## Requirements
Our examples have very basic requirements:

1. An account with [Travis](travis-ci.org)
2. A source code repository on github that Travis can retrieve.
3. A dothub account to save your data states.

## Running the Demo

TL;DR

1. Set up a Travis account
2. Connect Travis to your repository
3. Get a dothub account and API key, and save it to travis
4. Modify your `.travis.yml` to initialize dotmesh
5. Modify your test launcher to use dotmesh volumes
6. Modify your `.travis.yml` to capture data after tests are complete

### Set up a Travis account
If you already have a Travis account, you can skip this step.

If you do not, go to https://travis-ci.org and sign up for an account.

### Connect Your Repository
With a Travis account ready, you need to configure it to monitor your repository for changes.

NOTE: If your repository is part of a namespace that already has every repository monitored and built by Travis, you can skip this step.

To connect a single repository:

1. Go to the Travis account page, either https://travis-ci.org or https://travis-ci.com
2. Search for your repository
3. Select the repository and click activate

You should feel free to use [our sample repository](https://github.com/dotmesh-io/ci-example/). It has a functional `travis.yml` that fulfills all of the required steps.

### Register for a dothub account and get your API key
Go to https://dothub.com and register for an account. Once that is done, retrieve your API key and save it.
The API key is available under "Settings" -> "Api Key".

Your testing scripts will need access to the API key. You can save it either as an environment variable under "Settings" for the individual repository, or for your entire account. Save your username as `DOTHUB_USER` and your API key as `DOTHUB_KEY`.

### Modify your travis.yml to initialize dotmesh
Initializing dotmesh using the following process:

1. Download the dotmesh client `dm`: `sudo curl -oL /usr/local/bin/dm https://get.dotmesh.io/$(uname -s)/dm && chmod +x /usr/local/bin/dm`.
2. Initialize a dotmesh cluster: `dm cluster init`
3. Add the dothub as a remote: `dm remote add dothub <youraccount>@dothub.com` . This step is optional; you always can capture states and keep them local. However, it is extremely useful to be able to save your states in a central hub, and recall them afterwards.

The example `travis.yml` in [our sample repository](https://github.com/dotmesh-io/ci-example/) already has this code set up in steps. That example also uses `docker-compose` file format v3.4, so we upgrade the version of the `docker-compose` binary to 1.18.0.

### Modify your test launcher to use dotmesh volumes
A normal test run would include a `travis.yml` snippet that looks something like this:

```yml
script:
- make test
```

In this example, our `Makefile` target named `test` just runs `docker-compose -f docker-compose.yml run test`. In order to use dotmesh volumes instead of the usual ephemeral directories, we extend our compose file with:

```yml
volumes:
  ciexample.redis:
    driver: dm
    name: ${VOL_ID}.redis
  ciexample.mysql:
    driver: dm
    name: ${VOL_ID}.mysql
```


### Modify your travis.yml to capture data after tests are complete
Once the tests are done, we want to capture the state of CI. However, we will not do the capture from just another `script` step. If we did, we would miss a failure that caused it to exit. Instead, we will capture it from with in an `after_script` step:

```yml
after_script:
  - dm switch ${VOL_ID} && dm commit -m "CI run $(date)" && dm push dothub --remote-name ${REMOTE_ID}
```

If you only want to catch failures, replace `after_script` with `after_failure`.

## Summary
You now have a fully functional Continuous Integration that:

1. Runs your app
2. Captures its states from multiple databases
3. Saves the state at the end of the CI run, whether it succeeds or fails, as a single dot
4. Pushes the dot to dothub, where you can view it, use it and retrieve it for further analysis

**Important Note:** Nothing about our `travis.yml` is unique to any of our repos. All of the settings are defined either in environment variables at the beginning of the `travis.yml` or as credentials in your travis account.
