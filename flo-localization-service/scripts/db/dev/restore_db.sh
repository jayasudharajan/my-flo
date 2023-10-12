#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

psql $(DATABASE_URL) < db-dump.sql