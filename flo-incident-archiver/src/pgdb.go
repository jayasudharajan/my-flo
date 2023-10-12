package main

import (
	"database/sql"
	"errors"
	"fmt"

	_ "github.com/lib/pq"
)

type PgSqlDb struct {
	ConnectionString string
	Connection       *sql.DB
}

func OpenPgSqlDb(cnString string) (*PgSqlDb, error) {
	// Open Database Connection
	db, err := sql.Open("postgres", cnString)

	if err != nil {
		return nil, err
	}

	// Ensure we can reach the DB and its working
	err = db.Ping()
	if err != nil {
		return nil, err
	}

	rv := new(PgSqlDb)
	rv.Connection = db
	rv.ConnectionString = cnString

	return rv, nil
}

func (db *PgSqlDb) Close() {
	if db == nil {
		return
	}

	db.Connection.Close()
	db.Connection = nil
	db.ConnectionString = ""
}

func (db *PgSqlDb) Exec(sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, errors.New("Exec: db or connection is nil")
	}
	return db.Connection.Exec(sqlStatement, args...)
}

func (db *PgSqlDb) Query(sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, errors.New("Query: db or connection is nil")
	}

	rows, err := db.Connection.Query(sqlStatement, args...)

	if err != nil {
		return nil, errors.New(fmt.Sprintf("Query: %v %v", sqlStatement, err))
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, errors.New("Query: db or connection is nil")
	}

	row := db.Connection.QueryRow(sqlStatement, args...)

	return row, nil
}
