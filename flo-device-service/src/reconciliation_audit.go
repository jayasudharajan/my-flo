package main

import (
	"database/sql"
	"strings"
	"time"
)

type ReconAudit interface {
	Store(l *ReconLog) error
	RemoveBefore(dt time.Time) (int64, error)
}

type reconAudit struct {
	pg *sql.DB
}

func CreateReconAudit(pg *sql.DB) ReconAudit {
	return &reconAudit{pg}
}

type ReconLog struct {
	Type      string `json:"level_type"`
	EntityId  string `json:"entity_id"`
	NewTarget string `json:"new_target"`
	Context   *SystemModeReconciliation
	Reason    string `json:"reason"`
}

func (l *ReconLog) TypeValue() int32 {
	if strings.EqualFold(l.Type, "location") {
		return 1
	}
	return 0
}

func (l ReconLog) String() string {
	return toJson(l)
}

func (r *reconAudit) Store(l *ReconLog) error {
	defer panicRecover("ReconAudit.Store: %v", l)

	const sql = `insert into reconciliation (level_type,entity_id,new_target,context,reason) values ($1,$2,$3,$4,$5);`
	args := []interface{}{l.TypeValue(), strings.ToLower(l.EntityId), strings.ToLower(l.NewTarget), l.Context, l.Reason}
	if _, e := r.pg.Exec(sql, args...); e != nil {
		logError("ReconAudit.Store: %v | %v", l, e)
		return e
	}
	return nil
}

func (r *reconAudit) RemoveBefore(dt time.Time) (int64, error) {
	defer panicRecover("ReconAudit.RmB4: %v", dt)

	const sql = `delete from reconciliation where changed < $1;`
	var (
		start = time.Now()
		n      int64
		res, e = r.pg.Exec(sql, dt.UTC())
	)
	if e == nil {
		n, e = res.RowsAffected()
	}
	if e != nil {
		logError("ReconAudit.RmB4: %v | %v", dt, e)
	} else {
		logInfo("ReconAudit.RmB4: %v | deleted %v items | took %v", dt, n, time.Since(start))
	}
	return n, e
}
