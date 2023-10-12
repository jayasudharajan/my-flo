#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

# migrate up
psql $DATABASE_URL < scripts/sql/migrations/20190620-1515-telemetry-table-up.sql