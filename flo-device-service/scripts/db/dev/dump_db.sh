#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

DUMP_FILE=db_dump.sql

pg_dump -U admin --format=plain --no-owner --no-acl $(DATABASE_URL) | sed -E 's/(DROP|CREATE|COMMENT ON) EXTENSION/-- \1 EXTENSION/g' > $(DUMP_FILE)