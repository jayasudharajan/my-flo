package main

import (
	"context"
	"database/sql"

	"github.com/lib/pq"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

type PgSqlDb struct {
	ConnectionString string
	Connection       *sql.DB
}

func OpenPgSqlDb(ctx context.Context, cnString string) (*PgSqlDb, error) {
	var db *sql.DB
	var err error
	// Open Database Connection
	db, err = tracing.WrapSqlOpen(tracing.Instana, "postgres", pq.Driver{}, cnString)

	if err != nil {
		return nil, err
	}

	// Ensure we can reach the DB and its working
	err = db.PingContext(ctx)
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

func (db *PgSqlDb) ExecNonQuery(ctx context.Context, sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Exec: db or connection is nil")
	}
	return db.Connection.ExecContext(ctx, sqlStatement, args...)
}

func (db *PgSqlDb) Query(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Query: db or connection is nil")
	}

	rows, err := db.Connection.QueryContext(ctx, sqlStatement, args...)

	if err != nil {
		return nil, logError("Query: %v %v", sqlStatement, err.Error())
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, logError("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRowContext(ctx, sqlStatement, args...)

	return rows, nil
}
