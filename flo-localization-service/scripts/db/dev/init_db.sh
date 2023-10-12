#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

# init database
psql $DATABASE_URL < scripts/sql/init.sql
# add triggers
psql $DATABASE_URL < scripts/sql/trigger.sql
# populate locales table
psql $DATABASE_URL < scripts/sql/populate_locales_table.sql