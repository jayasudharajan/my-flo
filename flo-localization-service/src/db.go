package main

import (
	"database/sql"
	"fmt"

	"github.com/labstack/gommon/log"
	_ "github.com/lib/pq"
)

const dialect = "postgres"

// DB is the global variable for the DB client
var DB *sql.DB

// InitRelationalDb initializes the db connection
func InitRelationalDb() (*sql.DB, error) {
	var err error

	connectionString := fmt.Sprintf("host=%s port=%s user=%s dbname=%s password=%s sslmode=disable",
		DbHost, DbPort, DbUser, DbName, DbPassword)
	log.Infof("db connection string: %s", connectionString)

	DB, err = sql.Open(dialect, connectionString)
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
