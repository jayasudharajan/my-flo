#!/bin/sh

docker-compose down && \
docker-compose -f docker-compose.yml -f docker-compose.build.yml up --remove-orphans --build