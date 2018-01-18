#!/bin/bash -e

# push the locally built production image to GCR using the variables defined
# in .gitlab-ci.yaml

set -e

IMAGE="$DOCKER_REGISTRY/$GCLOUD_PROJECT_ID/docs:$VERSION"

cat /app/deploy/00-namespace.yaml | envsubst
cat /app/deploy/ingress.yaml | envsubst
cat /app/deploy/service.yaml | envsubst
cat /app/deploy/deployment.yaml | envsubst