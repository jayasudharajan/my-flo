package main

import (
	sql2 "database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

type runRepo struct {
	validator *Validator
	pg        *PgSqlDb
	log       *Logger
}

func CreateRunRepo(pg *PgSqlDb, validator *Validator, log *Logger) *runRepo {
	q := runRepo{
		pg:        pg,
		validator: validator,
		log:       log.CloneAsChild("runDb"),
	}
	return &q
}

func (q *runRepo) Ping() error {
	_, e := q.pg.ExecNonQuery(`select id from email_schedule limit 0;`)
	return q.log.IfErrorF(e, "Ping")
}

func (rq *reqQaHistory) sqlQuery() *sqlContext {
	var (
		sql       = sqlContext{make([]interface{}, 0), strings.Builder{}}
		dtEq, dir string
	)
	sql.sb.WriteString("select id,email_type,params,ok_count,err_count,completed,created from email_schedule ")
	if strings.EqualFold(rq.Direction, "asc") {
		dtEq, dir = ">=", "asc"
	} else {
		dtEq, dir = "<=", "desc"
	}
	if dtOK := rq.Date.Year() > 2000; dtOK || rq.EmailType > 0 || rq.DryRun != nil {
		if !dtOK && rq.EmailType > 0 { //optimize query to hit index
			if dir == "desc" {
				rq.Date = time.Now().UTC()
			} else {
				rq.Date = time.Unix(0, 0)
			}
		}
		sql.sb.WriteString(" where ")
		if rq.Date.Year() > 2000 {
			if len(sql.args) != 0 {
				sql.sb.WriteString(" and ")
			}
			sql.args = append(sql.args, rq.Date)
			sql.sb.WriteString(fmt.Sprintf(" created %v $%v", dtEq, len(sql.args)))
		}
		if rq.EmailType > 0 {
			if len(sql.args) != 0 {
				sql.sb.WriteString(" and ")
			}
			sql.args = append(sql.args, rq.EmailType)
			sql.sb.WriteString(fmt.Sprintf(" email_type = $%v", len(sql.args)))
		}
		if rq.DryRun != nil {
			if len(sql.args) != 0 {
				sql.sb.WriteString(" and ")
			}
			if *rq.DryRun != true {
				sql.sb.WriteString(" not ") //json query hack because property exists check is only possible w/ JSONB!
			}
			sql.sb.WriteString(" (params->>'dryRun'='true') ")
		}
	}
	sql.args = append(sql.args, rq.Limit)
	sql.sb.WriteString(fmt.Sprintf(" order by id %v limit $%v;", dir, len(sql.args)))
	return &sql
}

func (a reqQueueAll) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *reqQueueAll) Scan(value interface{}) error {
	if a == nil || value == nil {
		return nil
	} else if buf, ok := value.([]byte); !ok {
		return errors.New("type assertion to []byte failed")
	} else {
		return json.Unmarshal(buf, &a)
	}
}

// fetch assumes validation is already done up stream. real data
func (q *runRepo) Fetch(rq *reqQaHistory) ([]*respQaHistRun, error) {
	started := time.Now()
	q.log.PushScope("Fetch", rq.EmailType, rq.Date.Format(FMT_DT_NO_TZ))
	defer q.log.PopScope()

	sql := rq.sqlQuery()
	if rows, e := q.pg.Query(sql.sb.String(), sql.args...); e != nil {
		return nil, q.log.IfErrorF(e, "select | %v", sql.args)
	} else {
		defer rows.Close()
		res := make([]*respQaHistRun, 0)
		es := make([]error, 0)
		for rows.Next() {
			r := respQaHistRun{Params: &reqQueueAll{}}
			var done sql2.NullTime
			if e := rows.Scan(&r.Id, &r.EmailType, r.Params, &r.Counter, &r.Errors, &done, &r.Created); e != nil {
				es = append(es, e)
			} else {
				if done.Valid {
					r.Completed = done.Time
				}
				res = append(res, &r)
			}
		}
		if e = q.log.IfWarnF(wrapErrors(es), "scan"); e == nil {
			q.log.Debug("%vms found %v", time.Since(started).Milliseconds(), len(res))
		}
		return res, e
	}
}

type QueueCountReq struct {
	ScheduleIds  []string  `json:"scheduleIds,omitempty" validate:"omitempty,max=500"`
	CreatedAfter time.Time `json:"createdAfter,omitempty"`
}

func (qc *QueueCountReq) buildSqlCx() *sqlContext {
	cx := sqlContext{
		sb:   strings.Builder{},
		args: make([]interface{}, 0),
	}
	cx.sb.WriteString("select schedule_id,count(*) as ct from email_queued ")
	if hasIds, hasDate := len(qc.ScheduleIds) != 0, qc.CreatedAfter.Year() > 2000; hasIds || hasDate {
		cx.sb.WriteString(" where ")
		if hasIds {
			cx.sb.WriteString(" schedule_id in ('")
			cx.sb.WriteString(strings.Join(qc.ScheduleIds, "','"))
			cx.sb.WriteString("') ")
		}
		if hasDate {
			if hasIds {
				cx.sb.WriteString(" and ")
			}
			cx.args = append(cx.args, qc.CreatedAfter)
			cx.sb.WriteString(fmt.Sprintf(" queue_dt>=$%v ", len(cx.args)))
		}
	}
	cx.sb.WriteString(" group by schedule_id ; ")
	return &cx
}

type QueueCountResp struct {
	Params *QueueCountReq   `json:"params"`
	Counts map[string]int32 `json:"scheduleCounts"`
}

func (r *runRepo) Count(rq *QueueCountReq) (*QueueCountResp, error) { //TODO: should probably move to queue repo instead
	r.log.PushScope("Count", rq)
	defer r.log.PopScope()

	if e := r.validator.Struct(rq); e != nil {
		return nil, r.log.IfWarnF(e, "Validation fail")
	}
	sql := rq.buildSqlCx()
	if rows, e := r.pg.Query(sql.sb.String(), sql.args...); e != nil {
		return nil, r.log.IfErrorF(e, "Query failed")
	} else {
		var (
			res = QueueCountResp{Params: rq, Counts: make(map[string]int32)}
			es  = make([]error, 0)
		)
		for rows.Next() {
			var runId string
			var count int32
			if e := rows.Scan(&runId, &count); e != nil {
				es = append(es, r.log.IfWarnF(e, "Scan failed"))
			} else {
				res.Counts[runId] = count
			}
		}
		return &res, wrapErrors(es)
	}
}

// validation within
func (q *runRepo) Store(rn *respQaHistRun) (string, error) {
	q.log.PushScope("Store", rn.EmailType)
	defer q.log.PopScope()

	if e := q.validator.Struct(rn); e != nil {
		return "", q.log.IfWarnF(e, "validation failed | %v", rn)
	}
	if rn.Created.Year() < 2000 {
		rn.Created = time.Now().UTC()
	}
	sql := `insert into email_schedule (id,email_type,params,created) values ($1,$2,$3,$4);`
	if _, e := q.pg.ExecNonQuery(sql, rn.Id, rn.EmailType, rn.Params, rn.Created); e != nil {
		return "", q.log.IfErrorF(e, "insert | %v", rn)
	} else {
		return rn.Id, nil
	}
}

func (q *runRepo) updateQuery(id string, counter, errors int32, done bool) *sqlContext {
	sql := sqlContext{make([]interface{}, 0), strings.Builder{}}
	sql.sb.WriteString("update email_schedule set ")
	if counter > 0 {
		if len(sql.args) != 0 {
			sql.sb.WriteString(", ")
		}
		sql.args = append(sql.args, counter)
		sql.sb.WriteString(fmt.Sprintf("ok_count=$%v", len(sql.args)))
	}
	if errors > 0 {
		if len(sql.args) != 0 {
			sql.sb.WriteString(", ")
		}
		sql.args = append(sql.args, errors)
		sql.sb.WriteString(fmt.Sprintf("err_count=$%v", len(sql.args)))
	}
	if done {
		if len(sql.args) != 0 {
			sql.sb.WriteString(", ")
		}
		sql.args = append(sql.args, time.Now().UTC())
		sql.sb.WriteString(fmt.Sprintf("completed=$%v", len(sql.args)))
	}
	if len(sql.args) == 0 {
		return nil
	} else {
		sql.args = append(sql.args, id)
		sql.sb.WriteString(fmt.Sprintf(" where id=$%v;", len(sql.args)))
		return &sql
	}
}

func (q *runRepo) UpdateCounter(id string, counter, errors int32, done bool) error {
	q.log.PushScope("CountSave", id)
	defer q.log.PopScope()

	if e := q.validator.Value(id, "required,min=3,max=64"); e != nil {
		return q.log.IfWarnF(e, "update id")
	} else if e := q.validator.Value(counter, "min=0"); e != nil {
		return q.log.IfWarnF(e, "update counter")
	} else if e := q.validator.Value(errors, "min=0"); e != nil {
		return q.log.IfWarnF(e, "update errors")
	}

	if sql := q.updateQuery(id, counter, errors, done); sql == nil {
		return nil //nothing to update
	} else if _, e := q.pg.ExecNonQuery(sql.sb.String(), sql.args...); e != nil {
		return q.log.IfErrorF(e, "update") //problems
	} else {
		return nil //update OK
	}
}
