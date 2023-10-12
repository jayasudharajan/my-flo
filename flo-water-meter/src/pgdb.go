package main

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

type PgSqlDb struct {
	connectionString string
	Connection       *sql.DB
}

func OpenPgSqlDb(cnString string) (*PgSqlDb, error) {
	// Open Database Connection
	db, err := sql.Open("postgres", cnString)
	if err != nil {
		logError("OpenPgSqlDb: Open Attempt => %v", err.Error())
		return nil, err
	}

	rv := new(PgSqlDb)
	rv.Connection = db
	rv.connectionString = cnString
	return rv, nil
}

func (db *PgSqlDb) Close() {
	if db == nil {
		return
	}

	if db.Connection != nil {
		db.Connection.Close()
		db.Connection = nil
	}
	db.connectionString = ""
}

func (db *PgSqlDb) Ping() error {
	// Ensure we can reach the DB and its working
	if err := db.Connection.Ping(); err != nil {
		return logError("OpenPgSqlDb Ping -> %v", err.Error())
	} else {
		return nil
	}
}

func (db *PgSqlDb) ExecNonQuery(sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("ExecNonQuery: db or Connection is nil")
	}
	return db.Connection.Exec(sqlStatement, args...)
}

func (db *PgSqlDb) Query(sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Query: db or Connection is nil")
	}

	rows, err := db.Connection.Query(sqlStatement, args...)

	if err != nil {
		return nil, logError(fmt.Sprintf("Query: %v %v", sqlStatement, err.Error()))
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("QueryRow: db or Connection is nil")
	}

	rows := db.Connection.QueryRow(sqlStatement, args...)
	return rows, nil
}
