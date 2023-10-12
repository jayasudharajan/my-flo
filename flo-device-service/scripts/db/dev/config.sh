#!/usr/bin/env bash

# defaulted to dev env
DS_DB_NAME=device-service
DS_DB_HOST=dev-rds-cherry.dev.flocloud.co
DS_DB_PORT=5432
DS_DB_USER=flo-device-service
DS_DB_PASSWORD='qu3bifTh$dlitotNejShaxye*bkon'
#DS_DB_NAME=flo_devices_db
#DS_DB_HOST=localhost
#DS_DB_PORT=5432
#DS_DB_USER=admin
#DS_DB_PASSWORD=12345
DATABASE_URL=postgres://${DS_DB_USER}:${DS_DB_PASSWORD}@${DS_DB_HOST}:${DS_DB_PORT}/${DS_DB_NAME}?sslmode=disable
echo $DATABASE_URL