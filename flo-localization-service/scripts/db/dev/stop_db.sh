#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

if docker ps -la | grep -q ${LS_DB_NAME} ; then
    echo "killing Postgres node"
    docker rm -f ${LS_DB_NAME}
fi
