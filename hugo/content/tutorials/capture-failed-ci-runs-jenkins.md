+++
draft = false
title = "6. Capture failed CI runs in Jenkins"
synopsis = "Save failed CI runs"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

# Jenkins
We are going to use Jenkins to capture the state of your CI at the end of a run.

## Requirements
Our examples have very basic requirements:

1. A running Jenkins instance capable of running docker containers
2. The dotmesh CLI installed where Jenkins can run it. In the future, we plan to release a Jenkins plugin.
3. A source code repository somewhere that Jenkins can retrieve. In our example, we will be using a github repository, but you can use any source code server that Jenkins supports.
4. A dothub account to save your data states.

## Running the Demo

TL;DR

1. Install and configure Jenkins
2. Connect Jenkins to your repository
3. Get a dothub account and API key, and save it to Jenkins
4. Modify your Jenkinsfile to initialize dotmesh
5. Modify your test launcher to use dotmesh volumes
6. Modify your Jenkinsfile to capture data after tests are complete

### Installing Jenkins
If your Jenkins is up and running, you can skip this step.

Installing Jenkins is beyond the scope of this example, please see the Jenkins install docs for [Jenkins native](https://jenkins.io/doc/pipeline/tour/getting-started/) or as a [Docker container](https://github.com/jenkinsci/docker/blob/master/README.md) to get started. We provide a very short summary of running Jenkins as a Docker container to help you get started.

1. Run your Jenkins server. In our case, we are running a simple one-node master/agent. Adjust your volumes and ports if you want to customize. Note that you need the `docker` client binary installed, which, for reasons unknown, is not included with the jenkins image. You either can install it with `apt` or bind-mount it in from another container, as we have done.

```plain
$ docker run -v dockerbin:/usr/local/bin --rm docker
$ docker run -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v jenkins_home:/var/jenkins_home -v dockerbin:/usr/local/sbin --group-add root jenkins/jenkins:lts
```

2. Find your initial admin password key in the logs. It looks something like:

```plain
*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

54a9f5513fc04ed59977a219090f45ed

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************
```

3. Navigate to `https://localhost:8080`, enter the admin password, set up an admin user, and install plugins. The default should be sufficient for the most part, but you also need to enable the docker plugin.

### Connect Your Repository
With Jenkins installed, you need to configure it to monitor your repository for changes.

NOTE: If your repository is part of a namespace or server that already has every repository monitored by Jenkins, you can skip this step.

To connect a single repository:

1. Go to your Jenkins Web UI page, normally http://localhost:8080/
2. Select "New Item"
3. Give it a name, and select "Multibranch Pipeline", click "OK"
4. Add a source pointing to your repository, click "Save"

You should feel free to use [our sample repository](https://github.com/dotmesh-io/ci-example/). It has a functional Jenkinsfile that fulfills all of the required steps.

### Register for a dothub account and get your API key
Go to https://dothub.com and register for an account. Once that is done, retrieve your API key and save it.
The API key is available under "Settings" -> "Api Key".

Your Jenkins scripts will need access to the API key. Save it as a "Global Credential" of type username/password, and give it the unique name `DOTHUB_API_KEY`.

### Modify your Jenkinsfile to initialize dotmesh
Initializing dotmesh using the following process:

1. Download the dotmesh client `dm`: `curl -oL /usr/local/bin/dm https://get.dotmesh.io/$(uname -s)/dm && chmod +x /usr/local/bin/dm`. If you are running Jenkins in a container using the [default image](https://hub.docker.com/r/jenkins/jenkins/), the path `/usr/local/bin` is owned by root, while Jenkins runs as `USER jenkins`. In that case, we recommend installing in `/var/jenkins_hom/bin/`.
2. Initialize a dotmesh cluster: `dm cluster init`
3. Add the dothub as a remote: `dm remote add dothub <youraccount>@dothub.com` . This step is optional; you always can capture states and keep them local. However, it is extremely useful to be able to save your states in a central hub, and recall them afterwards.

The example `Jenkinsfile` in [our sample repository](https://github.com/dotmesh-io/ci-example/) already has this code set up in steps.

### Modify your test launcher to use dotmesh volumes
A normal test run would include a Jenkinsfile snippet that looks something like this:

```groovy
stage('test') {
    steps {
        sh 'make test'
    }
}
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


### Modify your Jenkinsfile to capture data after tests are complete
Once the tests are done, we want to capture the state of CI. However, we will not do the capture from within a normal "stage" of the Jenkins pipeline. If we did, we would miss a failure that caused it to exit. Instead, we will capture it from with in a `post` step:

```groovy
post {
    always {
        sh 'dm switch ${VOL_ID} && dm commit -m "CI run $(date)" && dm push dothub --remote-name ${REMOTE_ID}'
    }
}
```

## Summary
You now have a fully functional Continuous Integration that:

1. Runs your app
2. Captures its states from multiple databases
3. Saves the state at the end of the CI run, whether it succeeds or fails, as a single dot
4. Pushes the dot to dothub, where you can view it, use it and retrieve it for further analysis

**Important Note:** Nothing about our `Jenkinsfile` is unique to any of our repos. All of the settings are defined either in environment variables at the beginning of the `Jenkinsfile` or as credentials in your Jenkins instance.
