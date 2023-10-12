#!/usr/local/bin/bash
set -x

export INSTANA_LOG_LEVEL=DEBUG
export INSTANA_ENDPOINT_URL='https://example.com'
export AWS_EXECUTION_ENV='AWS_Lambda_'
# export INSTANA_SERVICE_NAME='flo-insta-tracing-unittest'

go test -v -timeout 15s
