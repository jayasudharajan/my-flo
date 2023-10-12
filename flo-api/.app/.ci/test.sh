#!/bin/bash

source .ci/.env.rc

set -euo pipefail

mkdir -p ${CI_ARTIFACTS_DIR}/logs
docker-compose run test; docker-compose down
docker-compose logs | tee ${CI_ARTIFACTS_DIR}/logs/test.log

if [[ "${CI_SYSTEM}" == "circleci" ]]
then
  cp -R ${CI_PROJECT_DIR}/test-results/* ${CIRCLE_TEST_REPORTS}/
fi
