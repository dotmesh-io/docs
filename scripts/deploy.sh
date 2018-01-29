#!/bin/bash -e

set -e

function deploy-manifest() {
  local filename="$1"
  echo "running manifest: $filename"
  cat "/app/$filename" | envsubst
  cat "/app/$filename" | envsubst | kubectl apply -f -
}

deploy-manifest deploy/deployment.yaml
