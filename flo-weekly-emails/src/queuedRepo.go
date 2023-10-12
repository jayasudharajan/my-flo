package main

import (
	sql2 "database/sql"
	"fmt"
	"strings"
	"time"
)

type queuedRepo struct {
	validator *Validator
	pg        *PgSqlDb
	log       *Logger
}

func CreateQueueRepo(pg *PgSqlDb, validator *Validator, log *Logger) *queuedRepo {
	q := queuedRepo{
		pg:        pg,
		validator: validator,
		log:       log.CloneAsChild("queDb"),
	}
	return &q
}

func (q *queuedRepo) Ping() error {
	_, e := q.pg.ExecNonQuery(`select id from email_queued limit 0;`)
	return q.log.IfErrorF(e, "Ping")
}

// inclusive dt, real data. Assumes input has been scrubbed up stream
func (qr *queuedRepo) FetchAfter(dt time.Time, emailType int32, locId string) (userMap map[string]bool, err error) {
	started := time.Now()
	qr.log.PushScope("After", dt.Truncate(DUR_WEEK).Format("20060102T150405"), emailType, locId)
	defer qr.log.PopScope()

	if dt.Year() < 2000 || emailType < 1 || len(locId) == 0 {
		return map[string]bool{}, nil
	}
	var (
		q = `select user_id from email_queued where 
		queue_dt>='%v' and loc_id='%v' and email_type=%v and error_week is null and queue_req->>'force'='false';`
		p = []interface{}{
			dt.Truncate(DUR_WEEK).Format("2006-01-02 15:04:05"),
			locId,
			emailType,
		}
		sql = fmt.Sprintf(q, p...)
	)
	if rows, e := qr.pg.Query(sql); e != nil {
		return nil, qr.log.IfErrorF(e, "query | %v", p)
	} else {
		defer rows.Close()
		es := make([]error, 0)
		userMap := make(map[string]bool)
		for rows.Next() {
			var uid string
			if e := rows.Scan(&uid); e != nil {
				es = append(es, e)
			} else {
				userMap[strings.ToLower(uid)] = true
			}
		}
		if e := qr.log.IfWarnF(wrapErrors(es), "scan"); e == nil {
			qr.log.Debug("%vms len=%v | %v", time.Since(started).Milliseconds(), len(userMap), userMap)
		}
		return userMap, e
	}
}

func (rq *reqQueueHst) hasPredicate() bool {
	return rq.Date.Year() > 2000 || rq.LocId != "" || rq.UserId != "" || rq.Email != ""
}

type sqlContext struct {
	args []interface{}
	sb   strings.Builder
}

func (rq *reqQueueHst) sqlAppendWhereClause(cx *sqlContext) bool {
	predicates := 0
	if rq.Date.Year() > 2000 {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.sb.WriteString(" queue_dt")
		if strings.EqualFold(rq.Direction, "asc") {
			cx.sb.WriteString(">=$")
		} else {
			cx.sb.WriteString("<=$")
		}
		cx.args = append(cx.args, rq.Date)
		cx.sb.WriteString(fmt.Sprint(len(cx.args)))
		predicates++
	}
	if rq.EmailType > 0 {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.args = append(cx.args, rq.EmailType)
		cx.sb.WriteString(fmt.Sprintf(" email_type=$%v", len(cx.args)))
		predicates++
	}
	if rq.LocId != "" {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.args = append(cx.args, rq.LocId)
		cx.sb.WriteString(fmt.Sprintf(" loc_id=$%v", len(cx.args)))
		predicates++
	}
	if rq.UserId != "" {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.args = append(cx.args, rq.UserId)
		cx.sb.WriteString(fmt.Sprintf(" user_id=$%v ", len(cx.args)))
		predicates++
	}
	if rq.ScheduleId != "" {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.args = append(cx.args, rq.ScheduleId)
		cx.sb.WriteString(fmt.Sprintf(" schedule_id=$%v ", len(cx.args)))
		predicates++
	}
	if rq.Email != "" {
		if predicates > 0 {
			cx.sb.WriteString(" and ")
		}
		cx.args = append(cx.args, rq.Email)
		cx.sb.WriteString(fmt.Sprintf(" email=$%v ", len(cx.args)))
		predicates++
	}
	return predicates > 0
}

func (rq *reqQueueHst) sqlBuildQuery() *sqlContext {
	sql := sqlContext{args: make([]interface{}, 0), sb: strings.Builder{}}
	sql.sb.WriteString(`select 
	id,schedule_id,loc_id,user_id,email,email_type,template_id,template_data,queue_dt,queue_req,COALESCE(error, '') error 
	from email_queued `)
	if rq.hasPredicate() {
		sql.sb.WriteString(" where ")
		rq.sqlAppendWhereClause(&sql)
	}
	if strings.EqualFold(rq.Direction, "asc") {
		sql.sb.WriteString(" order by id asc ")
	} else {
		sql.sb.WriteString(" order by id desc ")
	}
	sql.args = append(sql.args, rq.Limit)
	sql.sb.WriteString(fmt.Sprintf(" limit $%v;", len(sql.args)))
	return &sql
}

// Read data. Assumes input has been scrubbed up stream
func (q *queuedRepo) Fetch(rq *reqQueueHst) ([]*emailQueued, error) {
	started := time.Now()
	q.log.PushScope("Fetch")
	defer q.log.PopScope()

	sql := rq.sqlBuildQuery()
	if rows, e := q.pg.Query(sql.sb.String(), sql.args...); e != nil {
		return nil, q.log.IfErrorF(e, "select | %v", sql.args)
	} else {
		defer rows.Close()
		es := make([]error, 0)
		res := make([]*emailQueued, 0)
		for rows.Next() {
			h := emailQueued{}
			template, request := PgJSON{}, PgJSON{}
			var schId sql2.NullString
			if e := rows.Scan(&h.Id, &schId, &h.LocId, &h.UserId, &h.Email, &h.EmailType, &h.TemplateId, &template, &h.Created, &request, &h.Error); e != nil {
				es = append(es, e)
			} else {
				if schId.Valid {
					h.ScheduleId = schId.String
				}
				h.TemplateData = template
				h.Request = request
				res = append(res, &h)
			}
		}
		if e = q.log.IfWarnF(wrapErrors(es), "scan"); e == nil {
			q.log.Debug("%vms found %v", time.Since(started).Milliseconds(), len(res))
		}
		return res, e
	}
}

//validation within
func (q *queuedRepo) Store(v *emailQueued) (id int64, e error) {
	q.log.PushScope("Store", v.LocId, v.UserId)
	defer q.log.PopScope()

	if e := q.validator.Struct(v); e != nil {
		return 0, q.log.IfWarnF(e, "validation failed | %v", v)
	}
	if v.Created.Year() < 2000 {
		v.Created = time.Now().UTC()
	}
	var (
		template PgJSON = v.TemplateData
		request  PgJSON = v.Request
		sql             = `insert into email_queued 
	(schedule_id,loc_id,user_id,email,email_type,template_id,template_data,queue_dt,queue_req,error_week,error) 
	values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id;`
		errWk  *int32
		errStr *string
		schId  *string
	)
	if v.Error != "" {
		yy, wk := v.Created.ISOWeek()
		i := int32(((yy - 2000) * 100) + wk)
		errWk = &i
		errStr = &v.Error
	}
	if v.ScheduleId != "" {
		schId = &v.ScheduleId
	}
	if row, e := q.pg.QueryRow(sql,
		schId, v.LocId, v.UserId, v.Email, v.EmailType, v.TemplateId, template, v.Created, request, errWk, errStr); e != nil {
		return 0, q.log.IfErrorF(e, "insert | %v", v)
	} else if e = row.Scan(&id); e != nil {
		return 0, q.log.IfWarnF(e, "scan | type=%v %v", v.EmailType, v.Email)
	} else {
		return id, nil
	}
}
