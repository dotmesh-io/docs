#!/bin/bash -e

# run a docker container that has gcloud installed alongside the docker binary
# this enables us to push images to GCR and manifests to GKE

set -e

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash /ciscripts/ci.sh connect
kubectl get no