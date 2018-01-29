#!/bin/bash -e

# push the locally built production image to GCR using the variables defined
# in .gitlab-ci.yaml

set -e

function deploy-manifest() {
  local filename="$1"
  echo "running manifest: $filename"
  cat "/app/$filename" | envsubst
  cat "/app/$filename" | envsubst | kubectl apply -f -
}

deploy-manifest deploy/00-namespace.yaml
deploy-manifest deploy/ingress.yaml
deploy-manifest deploy/service.yaml
deploy-manifest deploy/deployment.yaml
