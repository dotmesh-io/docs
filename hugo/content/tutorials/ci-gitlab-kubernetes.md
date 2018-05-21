+++
draft = false
title = "CI with GitLab and Kubernetes"
synopsis = "Save failed CI runs using Dotmesh, Gitlab and Kubernetes"
knowledgelevel = ""
date = 2017-12-21T11:27:29Z
weight = "7"
[menu]
  [menu.main]
    parent = "tutorials"
+++

{{% overview %}}
* A local installation of [Dotmesh on Docker](/install-setup/docker/).
* A Dotmesh GKE cluster ([install guide](/install-setup/gke/)).
* The Helm client binary [download](https://github.com/kubernetes/helm)
{{% /overview %}}


Good practice says to get your acceptance test environment as close as possible to your production environment.

If we are running Kubernetes, this means connecting a CI server (like Gitlab) to your cluster so it can run jobs inside Pods.

Using dotmesh alongside this setup gives you a powerful way to capture the stateful components of CI test runs and push their state to a remote cluster for later inspection.

## setup

This tutorial will show how to use Gitlab to deploy a stack and run the test suite on Kubernetes.

Before you begin - please complete the [Dotmesh on Docker](/install-setup/docker/) and [Dotmesh GKE cluster](/install-setup/gke/) installation guides.

### cluster check

Let's check to see that we have our dotmesh pods running on our Kubernetes cluster:

{{< copyable name="step-01" >}}
kubectl get po -n dotmesh
{{< /copyable >}}

```plain
NAME                                           READY     STATUS        RESTARTS   AGE
dotmesh-5hg2g                                  1/1       Running       0          1h
dotmesh-6fthj                                  1/1       Running       0          1h
dotmesh-dynamic-provisioner-7b766c4f7f-hkjkl   1/1       Running       0          1h
dotmesh-etcd-cluster-0000                      1/1       Running       0          1h
dotmesh-etcd-cluster-0001                      1/1       Running       0          1h
dotmesh-etcd-cluster-0002                      1/1       Running       0          1h
dotmesh-rd9c4                                  1/1       Running       0          1h
etcd-operator-56b49b7ffd-529zn                 1/1       Running       0          1h
```

### dm remote check

Let's check that we have a remote for our Kubernetes cluster:

{{< copyable name="step-02" >}}
dm remote -v
{{< /copyable >}}

```plain
  gke   admin@35.197.226.3
* local admin@127.0.0.1
  origin        binocarlos@saas.dotmesh.io
```

If you don't see a `gke` remote add it like this:

{{< copyable name="step-03" >}}
export NODE_IP=$(kubectl get no -o wide | tail -n 1 | awk '{print $6}')
dm remote add gke admin@$NODE_IP
{{< /copyable >}}

```plain
API key: Paste your API key here, it won't be echoed!

Remote added.
```

### clone demo repo

Get a copy of the demo repo we will use in the tutorial:

{{< copyable name="step-04" >}}
git clone https://github.com/dotmesh-io/gitlab-k8s-example
cd gitlab-k8s-example
{{< /copyable >}}

## install helm

Now we install [helm](https://github.com/kubernetes/helm) which is a package manager for Kubernetes.

{{< copyable name="step-05" >}}
kubectl create clusterrolebinding tiller-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:default
helm init
{{< /copyable >}}

Wait a few moments for the Tiller pod to start up.

If you already have helm installed, make sure to install the latest version to match the recent version of Kubernetes on our cluster.

{{< copyable name="step-06" >}}
helm version
{{< /copyable >}}

```plain
Client: &version.Version{SemVer:"v2.8.0", GitCommit:"14af25f1de6832228539259b821949d20069a222", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.8.0", GitCommit:"14af25f1de6832228539259b821949d20069a222", GitTreeState:"clean"}
```

## install gitlab

Add the gitlab repo and tell helm to deploy:

{{< copyable name="step-07" >}}
helm repo add gitlab https://charts.gitlab.io
helm install --namespace gitlab --name gitlab -f deploy/gitlab/helm/values.yaml gitlab/gitlab
{{< /copyable >}}

This will output the information for our gitlab install.  We need the public IP so we ask `kubectl` to output:

{{< copyable name="step-08" >}}
kubectl get svc -n gitlab -w
{{< /copyable >}}


```plain
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          
gitlab-gitlab       LoadBalancer   10.59.249.55    <pending>           22:31902...63/TCP
```

After a short while, the `EXTERNAL-IP` for the `gitlab-gitlab` service will update.  When it does - tell gitlab to proceed by exporting a `GITLAB_URL` variable:

{{< copyable name="step-09" >}}
export GITLAB_IP="$(kubectl get svc --namespace gitlab gitlab-gitlab -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
helm upgrade gitlab --set externalUrl="http://$GITLAB_IP" gitlab/gitlab
{{< /copyable >}}

We wait for the gitlab pods to start - this can take a few minutes:

{{< copyable name="step-10" >}}
kubectl get po -n gitlab -w
{{< /copyable >}}

## login to gitlab

Wait a few moments then open your browser and you should see the gitlab login screen and can set the password:

{{< copyable name="step-11" >}}
open "http://$GITLAB_IP"
{{< /copyable >}}

## install gitlab runner

Open the `/admin/runners` page on the gitlab GUI - this will tell you the runner token - assing the token to the value of `GITLAB_RUNNER_TOKEN`:

```plain
export GITLAB_RUNNER_TOKEN=xxx
```

Now we create the secrets for the gitlab runner:

{{< copyable name="step-12" >}}
echo "$GITLAB_RUNNER_TOKEN" > runnertoken.txt
echo "http://$GITLAB_IP" > gitlaburl.txt
kubectl create ns gitlab-runner
kubectl create secret generic runnertoken --from-file=runnertoken.txt -n gitlab-runner
kubectl create secret generic gitlaburl --from-file=gitlaburl.txt -n gitlab-runner
rm -f runnertoken.txt gitlaburl.txt
{{< /copyable >}}

Finally we deploy the runner:

{{< copyable name="step-13" >}}
kubectl apply -f deploy/gitlab-runner/deployment.yaml
kubectl get po -n gitlab-runner -w
{{< /copyable >}}

You can check the runner is active by visiting the `/admin/runners` page again:

{{< copyable name="step-14" >}}
open "http://$GITLAB_IP/admin/runners"
{{< /copyable >}}

**NOTE** the gitlab runner itself is running inside a Docker container with the host Docker socket mounted.  You can see how it's setup [here](https://github.com/dotmesh-io/gitlab-k8s-example/tree/master/deploy/gitlab-runner)

## add ssh key

Add your public key to the `/profile/keys` page so you can push code to your new gitlab server.

```plain
cat ~/.ssh/id_rsa.pub
```

{{< copyable name="step-17" >}}
open "http://$GITLAB_IP/profile/keys"
{{< /copyable >}}

## create gitlab project

Create a gitlab project under the root namespace called `gitlab-k8s-example` - this should result in a project url of `/root/gitlab-k8s-example`.

{{< copyable name="step-15" >}}
open "http://$GITLAB_IP/projects/new"
{{< /copyable >}}

In our demo repo - let's add the git remote:

{{< copyable name="step-16" >}}
git remote add gitlab git@$GITLAB_IP:root/gitlab-k8s-example.git
{{< /copyable >}}

## service account

We need a [gcloud service account](https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform) that we will use to deploy to k8s from gitlab.

From the google console - [create a new service account](https://console.cloud.google.com/iam-admin/serviceaccounts/project) with the `Kubernetes Engine Admin` role.

Download the .json key for the service account to a file called `serviceaccount.json`.

## project variables


Visit the `/root/gitlab-k8s-example/settings/ci_cd` page of the gitlab server and open the `Secret variables` section.

{{< copyable name="step-19" >}}
open "http://$GITLAB_IP/root/gitlab-k8s-example/settings/ci_cd"
{{< /copyable >}}


Run the following script to get our variables and enter them:

{{< copyable name="step-18" >}}
bash scripts/get_variables.sh
{{< /copyable >}}

**NOTE** change `GCLOUD_CLUSTER_ID` and any other values to match if they are not correct

## push code

Now we can push our git repo to the Gitlab CI.  We have a `.gitlab-ci.yml` that will build and run our app.

{{< copyable name="step-20" >}}
git push gitlab master
{{< /copyable >}}

Now visit the pipelines page and you should see the result of your build:

{{< copyable name="step-21" >}}
open "http://$GITLAB_IP/root/gitlab-k8s-example/pipelines
{{< /copyable >}}

## persistent volume

The YAML we used for the Persistent Volume is shown here:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  namespace: ${NAMESPACE}
  name: test-pvc
  annotations:
    dotmeshNamespace: admin
    dotmeshName: ${NAMESPACE}
spec:
  storageClassName: dotmesh
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

And our test `.gitlab-ci.yaml` is shown here:

```yaml
test:
  stage: test
  variables:
    IMAGE: $DOCKER_REGISTRY/$GCLOUD_PROJECT_ID/$IMAGENAME:$CI_COMMIT_SHA
  before_script:
    - export NAMESPACE="test$(echo $CI_COMMIT_SHA | cut -c1-8)"
    - bash scripts/ci_connect.sh
    - echo $NAMESPACE
    - kubectl create ns $NAMESPACE
  script:
    - cat manifests/pvc.yaml | envsubst | kubectl apply -f -
    - cat manifests/job.yaml | envsubst | kubectl apply -f -
```

You can see how we are basing the `NAMESPACE` on the git hash and provisioning a `dotmesh` volume for the pod.

## Capture failure state

Once we have pushed our code to the pipeline - you should be able to see the volume using `dm list`:

{{< copyable name="step-22" >}}
dm list
{{< /copyable >}}

```plain
Current remote: gke (use 'dm remote -v' to list and 'dm remote switch' to switch)

  DOT           BRANCH  SERVER            CONTAINERS  SIZE       COMMITS  DIRTY  
  testb9fb4663  master  c4cfa57738286cf8              19.00 kiB  0        19.00 kiB
```

We switch to our volume and make a commit:

```plain
dm switch testb9fb4663
dm commit -m "gitlab failure state"
```

## Pull volume locally

We can now pull the volume locally and use it to debug or start our service against it:

```plain
dm clone gke testb9fb4663 master
dm remote switch local
dm list
```

## Push volume to dothub on failures

Rather than pull the volume to a development machine, you could even configure your gitlab server to push the volume to the [dothub](https://dothub.com) on test failures.

This example would need the `dm` binary installed and the `DOTMESH_PASSWORD` variable assigned:

```yaml
push_failed_volumes:
  stage: push_failed_volumes
  when: on_failure
  script:
    - dm remote add dothub USERNAME@dothub.com
    - dm switch $NAMESPACE
    - dm commit -m "CI failure $NAMESPACE $CI_COMMIT_SHA"
    - dm push dothub --remote-name "ci-fail-$NAMESPACE"
```


## Summary
You now have a fully functional Continuous Integration that:

1. Runs your app on Kubernetes
2. Provisions data dots for each stateful component
2. Captures the state of the failed test run
4. Pushes the dot to the dothub, where you can view it, use it and retrieve it for further analysis





