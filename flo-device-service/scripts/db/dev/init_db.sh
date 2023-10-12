#!/bin/bash

. ./scripts/db/dev/config.sh

# init database
psql $DATABASE_URL < scripts/sql/init.sql
# add triggers
psql $DATABASE_URL < scripts/sql/trigger.sql