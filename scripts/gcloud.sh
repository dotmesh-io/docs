#!/bin/bash -e

# run a docker container that has gcloud installed alongside the docker binary
# this enables us to push images to GCR and manifests to GKE

set -e

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export GCLOUD_IMAGE=${GCLOUD_IMAGE:="binocarlos/cibase:v6"}

docker run --rm ${DOCKER_ARGS} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${DIR}:/app \
  -e DOCKER_API_VERSION \
  -e DOCKER_REGISTRY \
  -e GCP_PROJECT_ID \
  -e GCP_ZONE \
  -e GCP_CLUSTER_ID \
  -e GCLOUD_SERVICE_KEY \
  -e NAMESPACE \
  -e HOSTNAME \
  ${GCLOUD_IMAGE} "$@"