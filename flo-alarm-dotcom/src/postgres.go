package main

import (
	"database/sql"
	"errors"

	_ "github.com/lib/pq"
)

type Postgres interface {
	Close()
	Ping() error

	ExecNonQuery(sqlStatement string, args ...interface{}) (sql.Result, error)
	Query(sqlStatement string, args ...interface{}) (*sql.Rows, error)
	QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error)
	Transaction(txFunc func(*sql.Tx) error) (err error)
}

type postgres struct {
	ConnectionString string
	Connection       *sql.DB
	log              Log
}

func CreatePgSqlDb(cnString string, log Log) (Postgres, error) {
	// Open Database Connection
	db, err := sql.Open("postgres", cnString)
	if err != nil {
		return nil, err
	}

	rv := new(postgres)
	rv.Connection = db
	rv.ConnectionString = cnString
	rv.log = log
	return rv, nil
}

func (db *postgres) Close() {
	if db == nil {
		return
	}

	if db.Connection != nil {
		db.Connection.Close()
		db.Connection = nil
	}
}

func (db *postgres) Ping() error {
	if db == nil {
		return errors.New("db ref is nil")
	} else if db.Connection == nil {
		return errors.New("db.Connection is nil")
	} else {
		return db.Connection.Ping()
	}
}

func (db *postgres) ExecNonQuery(sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Exec: db or connection is nil")
	}
	return db.Connection.Exec(sqlStatement, args...)
}

func (db *postgres) Query(sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Query: db or connection is nil")
	}

	rows, err := db.Connection.Query(sqlStatement, args...)

	if err != nil {
		return nil, db.log.Error("Query: %v %v", sqlStatement, err.Error())
	}

	return rows, nil
}

func (db *postgres) QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRow(sqlStatement, args...)

	return rows, nil
}

func (db *postgres) Transaction(txFunc func(*sql.Tx) error) (err error) {
	var tx *sql.Tx
	if tx, err = db.Connection.Begin(); err == nil {
		defer func() {
			if p := recover(); p != nil {
				err = tx.Rollback()
			} else if err != nil {
				err = tx.Rollback() // err is non-nil; don't change it
			} else {
				err = tx.Commit() // err is nil; if Commit returns error update err
			}
		}()
		err = txFunc(tx)
	}
	return
}
