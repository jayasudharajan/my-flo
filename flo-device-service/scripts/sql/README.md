# install
See https://github.com/golang-migrate/migrate/tree/master/cmd/migrate to install migrate. Set your environmen from vault.

# new change
To create a new up/down step use

`migrate create -ext sql -dir sql/migrations -seq [descriptive_name_here]`

# migrate up and down

To move forward use
`migrate -database postgres://${DS_DB_USER}:${DS_DB_PASSWORD}@${DS_DB_HOST}/${DS_DB_NAME}?x-migrations-table=device_migrations -path sql/migrations/ up`

To move backwards use
`migrate -database postgres://${DS_DB_USER}:${DS_DB_PASSWORD}@${DS_DB_HOST}/${DS_DB_NAME}?x-migrations-table=device_migrations -path sql/migrations/ down`

# best practices
On up scripts use transactions in order to create data such as

```
BEGIN;
    [..statements here..]
    COMMIT;
END;
```

On down scrips delete only what was created on the up step.

If an up step fails then fix the problem and force the step up or manually change the dirty flag on the migration table.