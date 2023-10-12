package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

type PgSqlDb struct {
	ConnectionString string
	Connection       *sql.DB
	log              *Logger
}

func CreatePgSqlDb(log *Logger, cnString string) (*PgSqlDb, error) {
	var db *sql.DB
	var err error
	// this WrapSqlOpen has to be done here at the db connection creation
	db, err = tracing.WrapSqlOpen(tracing.Instana, "postgres", pq.Driver{}, cnString)
	if err != nil {
		return nil, err
	}

	rv := new(PgSqlDb)
	rv.Connection = db
	rv.ConnectionString = cnString
	rv.log = log.CloneAsChild("pg")
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

func (db *PgSqlDb) Ping(ctx context.Context) error {
	if db == nil {
		return errors.New("db ref is nil")
	} else if db.Connection == nil {
		return errors.New("db.Connection is nil")
	} else {
		return db.Connection.PingContext(ctx)
	}
}

func (db *PgSqlDb) Exec(ctx context.Context, sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Exec: db or connection is nil")
	}
	return db.Connection.ExecContext(ctx, sqlStatement, args...)
}

func (db *PgSqlDb) Query(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Query: db or connection is nil")
	}

	rows, err := db.Connection.QueryContext(ctx, sqlStatement, args...)

	if err != nil {
		return nil, db.log.Error("Query: %v %v", sqlStatement, err.Error())
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, db.log.Error("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRowContext(ctx, sqlStatement, args...)

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
