#!/usr/bin/env bash

docker run -t -i -e DS_DB_HOST='tm11l3qkuy18ukh.cwshejozikzy.us-west-2.rds.amazonaws.com' -e DS_DB_NAME='postgres' -e DS_DB_USER='master' -e DS_DB_PASSWORD='new_password_234' -p 3000:3000 registry.gitlab.com/flotechnologies/app:latest