#!/usr/bin/env bash

###NOTE: postgres url requires substitution of special characters, e.g. @ -> %40
#LOCAL

#LS_DB_NAME=localization-service-db
#LS_DB_HOST=localhost
#LS_DB_PORT=5432
#LS_DB_USER=admin
#LS_DB_PASSWORD=12345

#DEV

LS_DB_HOST=1Password
LS_DB_PORT=5432
LS_DB_NAME=localization-service
LS_DB_USER=flo-localization-service
LS_DB_PASSWORD=1Password

#PROD

#LS_DB_HOST=1Password
#LS_DB_PORT=5432
#LS_DB_NAME=localization-service
#LS_DB_USER=master
#LS_DB_PASSWORD=1Password

DATABASE_URL=postgres://${LS_DB_USER}:${LS_DB_PASSWORD}@${LS_DB_HOST}:${LS_DB_PORT}/${LS_DB_NAME}?sslmode=disable
echo $DATABASE_URL