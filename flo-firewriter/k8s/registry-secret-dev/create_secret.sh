#!/bin/bash

set -xe

export AWS_PROFILE=flo-dev AWS_SDK_LOAD_CONFIG=1
export KOPS_STATE_STORE=s3://flo-k8s-kops

export APP_NAME=flo-firewriter

kops export kubecfg --name k8s.flocloud.co

# aws ecr get-login --no-include-email
DOCKER_PASSWORD=""
DOCKER_USER=flo-firewriter-k8s-dev
DOCKER_REGISTRY_SERVER=registry.gitlab.com

kubectl create secret docker-registry "${APP_NAME}-registry-secrets" \
    --namespace="${APP_NAME}" \
    --docker-server="${DOCKER_REGISTRY_SERVER}" \
    --docker-username="${DOCKER_USER}" \
    --docker-password="${DOCKER_PASSWORD}"
