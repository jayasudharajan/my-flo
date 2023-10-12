package main

import (
	"database/sql"
	"fmt"

	instana "github.com/instana/go-sensor"
	"github.com/labstack/gommon/log"
	pq "github.com/lib/pq"
)

const dialect = "postgres"

// DB is the global variable for the DB client
var DB *sql.DB

// InitRelationalDB initializes the db connection
func InitRelationalDB() (*sql.DB, error) {
	var err error

	connectionString := fmt.Sprintf("host=%s port=%s user=%s dbname=%s password=%s sslmode=disable",
		DbHost, DbPort, DbUser, DbName, DbPassword)
	log.Debugf("db connection string: %s", connectionString)

	// ref: https://www.ibm.com/docs/en/instana-observability/current?topic=go-collector-common-operations#database-clients
	instana.InstrumentSQLDriver(_instana, dialect, &pq.Driver{})

	DB, err = instana.SQLOpen(dialect, connectionString)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to DB: %s", err.Error())
	}

	err = DB.Ping()
	if err != nil {
		return nil, fmt.Errorf("failed to ping DB %s", connectionString)
	}

	DB.SetMaxIdleConns(DbMaxIdleConnections)
	DB.SetMaxOpenConns(DbMaxOpenConnections)

	stats := DB.Stats()
	log.Infof("there are %d open connections", stats.OpenConnections)
	return DB, nil
}
