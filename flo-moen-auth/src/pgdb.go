package main

import (
	"context"
	"database/sql"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

type PgSqlDb struct {
	ConnectionString string
	Connection       *sql.DB
}

func OpenPgSqlDb(cnString string) (*PgSqlDb, error) {
	// Open Database Connection
	db, err := tracing.WrapSqlOpen(tracing.Instana, "postgres", pq.Driver{}, cnString)

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

func (db *PgSqlDb) Ping(ctx context.Context) error {
	if db.Connection == nil {
		return _log.Error("db.Connection is nil")
	} else {
		return db.Connection.PingContext(ctx)
	}
}

func (db *PgSqlDb) ExecNonQuery(ctx context.Context, sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, _log.Error("Exec: db or connection is nil")
	}
	return db.Connection.ExecContext(ctx, sqlStatement, args...)
}

func (db *PgSqlDb) Query(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, _log.Error("Query: db or connection is nil")
	}

	rows, err := db.Connection.QueryContext(ctx, sqlStatement, args...)

	if err != nil {
		return nil, _log.Error("Query: %v %v", sqlStatement, err.Error())
	}

	return rows, nil
}

func (db *PgSqlDb) QueryRow(ctx context.Context, sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, _log.Error("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRowContext(ctx, sqlStatement, args...)

	return rows, nil
}
