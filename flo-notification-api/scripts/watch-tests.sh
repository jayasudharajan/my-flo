#!/bin/sh

docker-compose down && \
docker-compose -f docker-compose.yml -f docker-compose.watch-test.yml up --remove-orphans --build