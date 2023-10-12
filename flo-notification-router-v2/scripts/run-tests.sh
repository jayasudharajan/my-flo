#!/bin/sh

docker-compose down && \
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --remove-orphans --build