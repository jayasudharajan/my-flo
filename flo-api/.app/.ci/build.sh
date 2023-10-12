#!/bin/bash
source .ci/.env.rc
set -euo pipefail

# Create logs directory so we can use it later.
mkdir logs && mkdir -p ${CI_ARTIFACTS_DIR}/logs && sudo mount --bind logs ${CI_ARTIFACTS_DIR}/logs

# In case we don't have .ebextensions
mkdir -p ${CI_PROJECT_DIR}/.ebextensions/

# Copy .ebextentions
cp -R ${CI_PROJECT_DIR}/.app/.ebextensions/* ${CI_PROJECT_DIR}/.ebextensions/
echo $APPLICATION_VARS

#docker info
eval $(aws ecr get-login --profile default --region ${AWS_REGION})

# Run app build
docker-compose run build | tee ${CI_ARTIFACTS_DIR}/logs/build-app.log
