package main

import (
	"context"
	"database/sql"

	"github.com/uptrace/opentelemetry-go-extra/otelsql"
)

type PgSqlDb struct {
	ConnectionString string
	Connection       *sql.DB
	Log              *Logger
}

const dialect = "postgres"

func NewPgSqlDb(cnString string, log *Logger) (*PgSqlDb, error) {
	log = log.CloneAsChild("PG")
	if db, err := otelsql.Open(dialect, cnString); err != nil {
		return nil, log.IfErrorF(err, "NewPgSqlDb")
	} else {
		log.Info("NewPgSqlDb: OK")
		return &PgSqlDb{cnString, db, log}, nil
	}
}

func (db *PgSqlDb) Open() {
	if db == nil {
		return
	}

	if db.Connection == nil {
		var err error
		if db.Connection, err = otelsql.Open(dialect, db.ConnectionString); err != nil {
			db.Log.IfWarnF(err, "Open")
		} else {
			db.Log.Info("Open: OK")
		}
	} else {
		db.Log.Trace("Open: Already")
	}
}

func (db *PgSqlDb) Close() {
	if db == nil {
		return
	}

	if db.Connection != nil {
		if e := db.Connection.Close(); e != nil {
			db.Log.IfWarnF(e, "Close")
		} else {
			db.Log.Info("Close: OK")
		}
		db.Connection = nil
	} else {
		db.Log.Trace("Close: Already")
	}
}

func (db *PgSqlDb) ExecNonQuery(sqlStatement string, args ...interface{}) (sql.Result, error) {
	if db == nil || db.Connection == nil {
		return nil, db.Log.Error("Exec: db or connection is nil")
	}
	return db.Connection.ExecContext(context.TODO(), sqlStatement, args...)
}

func (db *PgSqlDb) Query(sqlStatement string, args ...interface{}) (*sql.Rows, error) {
	if db == nil || db.Connection == nil {
		return nil, db.Log.Error("Query: db or connection is nil")
	}

	rows, err := db.Connection.QueryContext(context.TODO(), sqlStatement, args...)
	if err != nil {
		return nil, db.Log.IfErrorF(err, "Query: %v", sqlStatement)
	}
	return rows, nil
}

func (db *PgSqlDb) QueryRow(sqlStatement string, args ...interface{}) (*sql.Row, error) {
	if db == nil || db.Connection == nil {
		return nil, db.Log.Error("Query: db or connection is nil")
	}

	rows := db.Connection.QueryRowContext(context.TODO(), sqlStatement, args...)
	return rows, nil
}
