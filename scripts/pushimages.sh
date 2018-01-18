#!/bin/bash -e

# push the locally built production image to GCR using the variables defined
# in .gitlab-ci.yaml

set -e

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOCAL_IMAGE="dotmeshio/docs:$VERSION"
GCR_IMAGE="$DOCKER_REGISTRY/$GCP_PROJECT_ID/docs:$VERSION"

docker tag "$LOCAL_IMAGE" "$GCR_IMAGE"
gcloud docker -- push "$GCR_IMAGE"