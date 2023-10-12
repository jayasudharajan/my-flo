#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

if docker ps -la | grep -q $DS_DB_NAME ; then
    echo "Database is running"
else
    docker run --name $DS_DB_NAME -p ${DS_DB_PORT}:${DS_DB_PORT} -e POSTGRES_PASSWORD=${DS_DB_PASSWORD} -e POSTGRES_USER=${DS_DB_USER} -e POSTGRES_DB=${DS_DB_NAME} -d postgres:11.2
    while true; do
    echo "Pinging Postgres DB ${DATABASE_URL}"
    # TODO: validate if psql is installed
    if psql $DATABASE_URL -c "select 1" &> /dev/null; then
        break
    fi
    sleep 1
done
fi