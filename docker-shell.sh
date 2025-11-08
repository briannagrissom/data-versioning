#!/bin/bash

set -e

export BASE_DIR=$(pwd)
export SECRETS_DIR=$(pwd)/../secrets/
export GCP_ZONE="us-central1-a"
export GOOGLE_APPLICATION_CREDENTIALS="/secrets/data-service-account.json"
export GCS_BUCKET_NAME="hw2-part2-bucket"
export GCP_PROJECT="ac215-471916" 




echo "Building image"
docker build -t data-version-cli -f Dockerfile .

echo "Running container"
docker run --rm --name data-version-cli -ti \
--privileged \
--cap-add SYS_ADMIN \
--device /dev/fuse \
-v "$BASE_DIR":/app \
-v "$SECRETS_DIR":/secrets \
-v ~/.gitconfig:/etc/gitconfig \
-e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
-e GCP_PROJECT=$GCP_PROJECT \
-e GCP_ZONE=$GCP_ZONE \
-e GCS_BUCKET_NAME=$GCS_BUCKET_NAME data-version-cli