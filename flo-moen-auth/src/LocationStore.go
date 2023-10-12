package main

import (
	"context"
	"database/sql"
	"fmt"
)

type LocationStore interface {
	GetList(ctx context.Context, match *getLocMatch, page *skipLimPage) ([]*SyncLoc, error)
	Save(ctx context.Context, loc *SyncLoc) error
	Remove(ctx context.Context, match *getLocMatch) ([]*SyncLoc, error)
}

func CreateLocationStore(
	log *Logger, pg *PgSqlDb, chk *Validator) LocationStore {
	return &locStore{log.CloneAsChild("LocRepo"), pg, chk}
}

type locStore struct {
	log *Logger
	pg  *PgSqlDb
	chk *Validator
}

func (ls *locStore) GetList(ctx context.Context, match *getLocMatch, page *skipLimPage) ([]*SyncLoc, error) {
	if pr, e := ls.predicate(match); e != nil {
		return nil, ls.log.IfWarnF(e, "GetList: check %v", match)
	} else {
		defer pr.Close()
		if page == nil {
			page = new(skipLimPage).Normalize()
		} else {
			page.Normalize()
		}
		pr.Append(" order by created asc") //done w/ query building
		pr.Append(" limit $%v", pr.Arg(page.Limit))
		if page.Skip > 0 {
			pr.Append(" offset $%v", pr.Arg(page.Skip))
		}

		var (
			stmt = "select flo_loc_id, moen_loc_id, flo_acc_id from linked_location where " + pr.String()
			res  *sql.Rows
			locs []*SyncLoc
		)
		if res, e = ls.pg.Query(ctx, stmt, pr.Args()...); e != nil {
			return nil, ls.log.IfErrorF(e, "GetList: execute %v", match)
		} else {
			defer res.Close()
			if locs, e = ls.scanLocs(res); e != nil {
				ls.log.IfErrorF(e, "GetList: scan %v", match)
			} else {
				ls.log.Debug("GetList: OK rows=%v | %v", len(locs), match)
			}
			return locs, e
		}
	}
}

func (ls *locStore) Save(ctx context.Context, loc *SyncLoc) error {
	if loc == nil {
		return ls.log.IfWarn(&HttpErr{400, "loc input is nil", false, nil})
	} else if e := ls.chk.Struct(loc); e != nil {
		return ls.log.IfWarnF(e, "Save: check %v", loc)
	} else {
		var (
			rows  int64
			res   sql.Result //note: all data are immutable, we could just ignore the conflicts
			query = `insert into linked_location (flo_loc_id, moen_loc_id, flo_acc_id) 
						values ($1, $2, $3)	on conflict (flo_loc_id) do nothing;`
		)
		if res, e = ls.pg.ExecNonQuery(ctx, query, loc.FloId, loc.MoenId, loc.FloAccId); e != nil {
			return ls.log.IfErrorF(e, "Save: query: %v", loc)
		} else if rows, e = res.RowsAffected(); e != nil {
			return ls.log.IfErrorF(e, "Save: read: %v", loc)
		} else {
			ls.log.Debug("Save: OK rows=%v | %v", rows, loc)
			return nil
		}
	}
}

func (ls *locStore) predicate(match *getLocMatch) (pr SqlBuilder, e error) {
	if e = match.Validate(ls.chk); e != nil {
		ls.log.IfWarnF(e, "predicate validation: %v", match)
	} else {
		pr = NewSqlBuilder()
		if match.FloId != "" {
			if pr.Len() > 0 {
				pr.Append(" and")
			}
			pr.Append(" flo_loc_id=$%v", pr.Arg(match.FloId))
		}
		if match.MoenId != "" {
			if pr.Len() > 0 {
				pr.Append(" and")
			}
			pr.Append(" moen_loc_id=$%v", pr.Arg(match.MoenId))
		}
		if match.FloAccId != "" {
			if pr.Len() > 0 {
				pr.Append(" and")
			}
			pr.Append(" flo_acc_id=$%v", pr.Arg(match.FloAccId))
		}
	}
	return
}

func (ls *locStore) scanLocs(res *sql.Rows) (locs []*SyncLoc, e error) {
	if res != nil {
		var lastEr error
		for res.Next() {
			l := SyncLoc{}
			if er := res.Scan(&l.FloId, &l.MoenId, &l.FloAccId); er != nil {
				lastEr = er
			} else {
				locs = append(locs, &l)
			}
		}
		if len(locs) == 0 && lastEr != nil {
			e = lastEr
		}
	}
	return
}

func (ls *locStore) Remove(ctx context.Context, match *getLocMatch) ([]*SyncLoc, error) {
	if pr, e := ls.predicate(match); e != nil {
		return nil, ls.log.IfErrorF(e, "Remove: validate %v", match)
	} else {
		var (
			locs []*SyncLoc
			res  *sql.Rows
			stmt = "delete from linked_location where %v returning flo_loc_id,moen_loc_id,flo_acc_id;"
		)
		defer pr.Close()
		stmt = fmt.Sprintf(stmt, pr.String())

		if res, e = ls.pg.Query(ctx, stmt, pr.Args()...); e != nil {
			return nil, ls.log.IfErrorF(e, "Remove: execute %v", match)
		} else {
			defer res.Close()
			if locs, e = ls.scanLocs(res); e != nil {
				ls.log.IfErrorF(e, "Remove: scan %v", match)
			} else {
				ls.log.Debug("Remove: OK rows=%v | %v", len(locs), match)
			}
			return locs, e
		}
	}
}
