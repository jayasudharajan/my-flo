#!/usr/bin/env bash

. ./scripts/db/dev/config.sh

# init database
psql $DATABASE_URL < scripts/sql/migrations/up/20190821-1728-type-table-up.sql
echo "created types table"

# create trigger
psql $DATABASE_URL < scripts/sql/migrations/up/20190821-1728-type-table-trigger-up.sql
echo "created types table trigger for created column"

# populate types table
psql $DATABASE_URL < scripts/sql/populate_types_table.sql
echo "populate types table"