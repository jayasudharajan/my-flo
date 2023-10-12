#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: run_local.sh DEPLOY_TOKEN"
    exit 1
fi;

DEPLOY_TOKEN=$1 docker-compose build
docker-compose up -d
