#!/usr/bin/env bash

#NOTE: script will start a local pgsql container & bind to local default port for debugging, 
#script will auto remove container on shut down, psql client is required

POSTGRES_PASSWORD=pwd
PGCLI=`command -v pgcli`
PGCLI=${PGCLI:-`command -v psql`}

if [[ $PGCLI == '' ]]; then
    echo 'pgcli or psql is not installed'
    exit 11
fi

echo 'starting weekly-emails. db will be removed on exit'
docker run -p 127.0.0.1:5432:5432/tcp --name weekly-emails -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -d postgres

echo "connecting to weekly-emails @localhost. Password is: ${POSTGRES_PASSWORD}"
sleep 2
$PGCLI -h localhost -U postgres

sleep 1
echo 'killing weekly-emails'
docker kill weekly-emails
docker rm weekly-emails