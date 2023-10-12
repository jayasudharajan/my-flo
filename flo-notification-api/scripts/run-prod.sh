#!/bin/sh

docker-compose down && \
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --remove-orphans --build