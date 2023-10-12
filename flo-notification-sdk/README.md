# flo-notification-sdk

Migrate your database using sbt flywayMigrate or clean it using sbt flywayClean.

## Run migrations on tests

sbt test:flywayMigrate

## Clean migrations on tests

sbt test:flywayClean


https://github.com/flyway/flyway-sbt
https://www.lewuathe.com/db-migration-with-flyway.html

./sbt -Dflyway.url=$JDBC_URL flywayMigrate