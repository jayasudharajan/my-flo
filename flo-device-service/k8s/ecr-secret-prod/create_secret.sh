#!/bin/bash

export AWS_PROFILE=flo-prod AWS_SDK_LOAD_CONFIG=1
export KOPS_STATE_STORE=s3://flosecurecloud-k8s-prod

kops export kubecfg --name oceanus.flosecurecloud.com
kubectl create ns flo-device-service
kubens flo-device-service

# aws ecr get-login --no-include-email
DOCKER_PASSWORD=
DOCKER_USER=AWS
DOCKER_REGISTRY_SERVER=098786959887.dkr.ecr.us-west-2.amazonaws.com

kubectl create secret docker-registry flo-dev-registry-secrets \
    --docker-server=$DOCKER_REGISTRY_SERVER \
    --docker-username=$DOCKER_USER \
    --docker-password=$DOCKER_PASSWORD