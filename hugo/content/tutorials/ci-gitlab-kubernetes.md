+++
draft = false
title = "7. CI with GitLab and Kubernetes"
synopsis = "Save failed CI runs"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
order = "1"
[menu]
  [menu.main]
    parent = "tutorials"
+++

# Gitlab and Kubernetes

Good practice says to get your acceptance test environment as close as possible to your production environment.

If we are running Kubernetes, this means connecting a CI server (like Gitlab) to your cluster so it can run jobs inside Pods.

Using dotmesh alongside this setup gives you a powerful way to capture the stateful components of CI test runs and push their state to a remote cluster for later inspection.

## setup

This tutorial will show how to use Gitlab to deploy a stack and run the test suite on Kubernetes.

{{% overview %}}
* A local installation of [Dotmesh on Docker](/install-setup/docker/).
* A Dotmesh GKE cluster ([install guide](/install-setup/gke/)).
* The Helm client binary [download](https://github.com/kubernetes/helm)
{{% /overview %}}

### cluster check

Let's check to see that we have our dotmesh pods running on our Kubernetes cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl get po -n dotmesh</kbd>
NAME                                           READY     STATUS        RESTARTS   AGE
dotmesh-5hg2g                                  1/1       Running       0          1h
dotmesh-6fthj                                  1/1       Running       0          1h
dotmesh-dynamic-provisioner-7b766c4f7f-hkjkl   1/1       Running       0          1h
dotmesh-etcd-cluster-0000                      1/1       Running       0          1h
dotmesh-etcd-cluster-0001                      1/1       Running       0          1h
dotmesh-etcd-cluster-0002                      1/1       Running       0          1h
dotmesh-rd9c4                                  1/1       Running       0          1h
etcd-operator-56b49b7ffd-529zn                 1/1       Running       0          1h
</pre></div>

### dm remote check

Let's check that we have a `gke` remote for our locally installed `dm` client:

<div class="highlight"><pre class="chromaManual">
$ <kbd>dm remote -v</kbd>
  gke   admin@35.197.226.3
* local admin@127.0.0.1
  origin        binocarlos@saas.dotmesh.io
</pre></div>

If you don't see a `gke` remote add it like this:

<div class="highlight"><pre class="chromaManual">
$ <kbd>export NODE_IP=$(kubectl get no -o wide | tail -n 1 | awk '{print $6}')</kbd>
$ <kbd>dm remote add gke admin@$NODE_IP</kbd>
API key: <kbd>Paste your API key here, it won't be echoed!</kbd>

Remote added.
</pre></div>

### clone demo repo

Get a copy of the demo repo we will use in the tutorial:

<div class="highlight"><pre class="chromaManual">
$ <kbd>git clone https://github.com/dotmesh-io/gitlab-k8s-example</kbd>
$ <kbd>cd gitlab-k8s-example</kbd>
</pre></div>

## service account

We need a [gcloud service account](https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform) that we will use to deploy to k8s from gitlab.

From the google console - [create a new service account](https://console.cloud.google.com/iam-admin/serviceaccounts/project?project=my-gcloud-project)

The required roles:

 * Compute Storage Admin
 * Kubernetes Engine Admin
 * Storage Admin

Download the .json key for the service account to a file called `serviceaccount.json`.

## install helm

Now we install [helm](https://github.com/kubernetes/helm) which is a package manager for Kubernetes.

First assign helm a ClusterRole so it can manage the cluster:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl create clusterrolebinding tiller-cluster-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:default</kbd>
</pre></div>

If you already have helm installed, make sure to install the latest version to match the recent version of Kubernetes on our cluster.

<div class="highlight"><pre class="chromaManual">
$ <kbd>helm init</kbd>
$ <kbd>helm version</kbd>
Client: &version.Version{SemVer:"v2.8.0", GitCommit:"14af25f1de6832228539259b821949d20069a222", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.8.0", GitCommit:"14af25f1de6832228539259b821949d20069a222", GitTreeState:"clean"}
</pre></div>

## install gitlab

Add the gitlab repo and tell helm to deploy:

<div class="highlight"><pre class="chromaManual">
$ <kbd>helm repo add gitlab https://charts.gitlab.io</kbd>
$ <kbd>helm install --namespace gitlab --name gitlab -f gitlab/helm/values.yaml gitlab/gitlab</kbd>
</pre></div>

This will output the information for our gitlab install.  We need the public IP so we ask `kubectl` to output:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl get svc -n gitlab -w</kbd>
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          
gitlab-gitlab       LoadBalancer   10.59.249.55    <pending>           22:31902...63/TCP
gitlab-postgresql   ClusterIP      10.59.248.191   <none>           5432/TCP         
gitlab-redis        ClusterIP      10.59.240.116   <none>           6379/TCP         
</pre></div>

After a short while, the `EXTERNAL-IP` for the `gitlab-gitlab` service will update.  When it does - tell gitlab to proceed by exporting a `GITLAB_URL` variable:

<div class="highlight"><pre class="chromaManual">
$ <kbd>export GITLAB_URL="http://$(kubectl get svc --namespace gitlab gitlab-gitlab -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"</kbd>
$ <kbd>helm upgrade gitlab --set externalUrl=$GITLAB_URL gitlab/gitlab</kbd>
</pre></div>

## login

We open our browser and we should see the gitlab login screen and we can set the password:

<div class="highlight"><pre class="chromaManual">
$ <kbd>open $GITLAB_URL</kbd>
</pre></div>

## gitlab runner

Open the `/admin/runners` page on the gitlab GUI - this will tell you the runner token - copy this and export it before making kubernetes secrets using these variables:

<div class="highlight"><pre class="chromaManual">
$ <kbd>export GITLAB_RUNNER_TOKEN=xxx</kbd>
$ <kbd>echo "$GITLAB_RUNNER_TOKEN" > runnertoken.txt && echo "$GITLAB_URL" > gitlaburl.txt</kbd>
$ <kbd>kubectl create secret generic runnertoken --from-file=runnertoken.txt -n gitlab-runner</kbd>
$ <kbd>kubectl create secret generic gitlaburl --from-file=gitlaburl.txt -n gitlab-runner</kbd>
$ <kbd>rm -f runnertoken.txt gitlaburl.txt</kbd>
</pre></div>

Now we actually deploy the runner using a local manifest from the example repo:

<div class="highlight"><pre class="chromaManual">
$ <kbd>kubectl apply -f gitlab-runner/deployment.yaml</kbd>
</pre></div>


