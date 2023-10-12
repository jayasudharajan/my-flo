package main

import (
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"

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

	rv := new(PgSqlDb)
	rv.Connection = db
	rv.ConnectionString = cnString
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
}

func (db *PgSqlDb) ExecNonQuery(sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Exec: db or connection is nil")
	}
	return db.Connection.Exec(sqlStatement, args...)
}

func (db *PgSqlDb) Query(sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Query: db or connection is nil")
	}

	rows, err := db.Connection.Query(sqlStatement, args...)

	if err != nil {
		return nil, logError("Query: %v %v", sqlStatement, err.Error())
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRow(sqlStatement, args...)

	return rows, nil
}

type PgJSON map[string]interface{}

func (a PgJSON) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *PgJSON) Scan(value interface{}) error {
	if a == nil || value == nil {
		return nil
	} else if buf, ok := value.([]byte); !ok {
		return errors.New("type assertion to []byte failed")
	} else {
		return json.Unmarshal(buf, &a)
	}
}
