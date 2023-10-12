#!/bin/sh
# This entrypoint allows container to stop gracefully
trap : TERM INT
tail -f /dev/null & wait
