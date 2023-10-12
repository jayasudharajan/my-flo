#!/bin/bash

set -xe

export AWS_PROFILE=flo-prod AWS_SDK_LOAD_CONFIG=1
export KOPS_STATE_STORE=s3://flosecurecloud-k8s-prod

export APP_NAME=flo-firewriter

kops export kubecfg --name oceanus.flosecurecloud.com

# aws ecr get-login --no-include-email
DOCKER_PASSWORD=""
DOCKER_USER=flo-firewriter-k8s-prod
DOCKER_REGISTRY_SERVER=registry.gitlab.com

kubectl create secret docker-registry "${APP_NAME}-registry-secrets" \
    --namespace="${APP_NAME}" \
    --docker-server="${DOCKER_REGISTRY_SERVER}" \
    --docker-username="${DOCKER_USER}" \
    --docker-password="${DOCKER_PASSWORD}"

