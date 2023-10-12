#!/bin/sh

ENVIRONMENT=$1

envsubst < k8s/pipeline-prod.yaml.tpl > k8s/pipeline.yaml
