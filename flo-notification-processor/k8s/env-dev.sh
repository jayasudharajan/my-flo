#!/bin/sh

ENVIRONMENT=$1

envsubst < k8s/pipeline-dev.yaml.tpl > k8s/pipeline.yaml
