#!/bin/bash -e

# build the docker image that has gcloud and the docker client inside
#
# NOTE: this should end up in a shared repo where each deplouyable repo can pull an image to use

set -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BASE_DIR="$SCRIPT_DIR/.."
export GCLOUD_IMAGE=${GCLOUD_IMAGE:="dotmesh/gcloud"}

docker build -t ${GCLOUD_IMAGE} -f "$BASE_DIR/Dockerfile.gcloud" "$BASE_DIR"
