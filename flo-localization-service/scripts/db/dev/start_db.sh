#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

if docker ps -la | grep -q $LS_DB_NAME ; then
    echo "Database is running"
else
    docker run --name $LS_DB_NAME -p ${LS_DB_PORT}:${LS_DB_PORT} -e POSTGRES_PASSWORD=${LS_DB_PASSWORD} -e POSTGRES_USER=${LS_DB_USER} -e POSTGRES_DB=${LS_DB_NAME} -d postgres:11.2
    while true; do
    echo "Pinging Postgres DB ${DATABASE_URL}"
    # TODO: validate if psql is installed
    if psql $DATABASE_URL -c "select 1" &> /dev/null; then
        break
    fi
    sleep 1
done
fi