#!/usr/bin/env bash

#NOTE: script will start a local pgsql container & bind to local default port for debugging, 
#script will auto remove container on shut down, psql client is required

REDISCLI=`command -v redis-cli`

if [[ $REDISCLI == '' ]]; then
    echo 'redis-cli is not installed'
    exit 11
fi

echo 'starting single node redis-cluster. data will be removed on exit'
docker run -d -p 127.0.0.1:6379:6379/tcp --name redis-cluster -e ALLOW_EMPTY_PASSWORD=yes -e REDIS_NODES=1 bitnami/redis-cluster:latest

echo "connecting to redis-cluster @localhost (no pwd)"
sleep 2
$REDISCLI -u redis://localhost -c

sleep 1
echo 'killing redis-cluster'
docker kill redis-cluster
docker rm redis-cluster