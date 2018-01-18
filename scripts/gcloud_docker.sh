#!/bin/bash -e

# run a docker container that has gcloud installed alongside the docker binary
# invoke the gcloud_auth_wrapper.sh script passing the command we want to run
#
# this will authenticate the gcloud cli using the GCLOUD_SERVICE_KEY var
#
# it then runs the command passed
#
# the build folder is mounted to /app so we can run scripts that are part
# of the repo
#
# this enables us to push images to GCR and manifests to GKE
#
#
# example usage: bash scripts/gcloud_docker.sh bash /app/pushimages.sh 

set -e

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export GCLOUD_IMAGE=${GCLOUD_IMAGE:="dotmesh/gcloud"}

docker build -t ${GCLOUD_IMAGE} -f "$DIR/../Dockerfile.gcloud" "$DIR/.."
docker run --rm ${DOCKER_ARGS} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${DIR}:/app \
  -e DOCKER_API_VERSION \
  -e DOCKER_REGISTRY \
  -e GCLOUD_PROJECT_ID \
  -e GCLOUD_ZONE \
  -e GCLOUD_CLUSTER_ID \
  -e GCLOUD_SERVICE_KEY \
  -e NAMESPACE \
  -e HOSTNAME \
  ${GCLOUD_IMAGE} bash -c "bash /app/scripts/gcloud_auth_wrapper.sh $@"