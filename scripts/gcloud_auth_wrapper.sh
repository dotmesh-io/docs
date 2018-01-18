#!/bin/bash -e
set -e

if [ -z "${GCLOUD_SERVICE_KEY}" ]; then
  echo >&2 "GCLOUD_SERVICE_KEY needed"
  exit 1
fi
if [ -z "${GCLOUD_PROJECT_ID}" ]; then
  echo >&2 "GCLOUD_PROJECT_ID needed"
  exit 1
fi
if [ -z "${GCLOUD_ZONE}" ]; then
  echo >&2 "GCLOUD_ZONE needed"
  exit 1
fi
if [ -z "${GCLOUD_CLUSTER_ID}" ]; then
  echo >&2 "GCLOUD_CLUSTER_ID needed"
  exit 1
fi
echo $GCLOUD_SERVICE_KEY | base64 -d > ${HOME}/gcloud-service-key.json
echo "activating gcloud service account"
gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
echo "set gcloud project $GCLOUD_PROJECT_ID"
gcloud config set project $GCLOUD_PROJECT_ID
echo "connect to container cluster $GCLOUD_CLUSTER_ID in $GCLOUD_ZONE"
gcloud container clusters get-credentials --zone $GCLOUD_ZONE $GCLOUD_CLUSTER_ID
eval "$@"