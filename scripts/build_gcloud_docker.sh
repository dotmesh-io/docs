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
# example usage: bash scripts/gcloud_docker.sh bash /app/pushimages.sh 
#
# NOTE: this should end up in a shared repo where each deplouyable repo can pull an image to use

set -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BASE_DIR="$SCRIPT_DIR/.."
export GCLOUD_IMAGE=${GCLOUD_IMAGE:="dotmesh/gcloud"}

docker build -t ${GCLOUD_IMAGE} -f "$BASE_DIR/Dockerfile.gcloud" "$BASE_DIR"
