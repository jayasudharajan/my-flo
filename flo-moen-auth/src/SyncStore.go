package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/go-redis/redis/v8"

	_ "github.com/lib/pq"
)

// SyncStore is CURD layer for pg table cognito_user & wrapped redis cache
type SyncStore interface {
	Check(ctx context.Context, moenId, floId string) (bool, error)
	GetMap(ctx context.Context, moenId, floId, issuer string) (*AccountMap, error)
	Save(ctx context.Context, am *AccountMap) error
	Remove(ctx context.Context, moenId, floId string) error
	GetByAccount(ctx context.Context, moeAccId, floAccId string, orPredicate bool) ([]*AccountMap, error)
}

type syncStore struct {
	pg    *PgSqlDb
	redis *RedisConnection
	valid *Validator
	log   *Logger
	expS  int //redis cache exp
}

func CreateSyncStore(
	log *Logger, pg *PgSqlDb, redis *RedisConnection, chk *Validator) SyncStore {
	var (
		redisTTLS, _ = strconv.Atoi(getEnvOrDefault("FLO_SYNC_STORE_REDIS_TTLS", "300"))
		clampTTLS    = clampInt(redisTTLS, 60, 60*60*24) //1day max for ttls
	)
	return &syncStore{
		pg,
		redis,
		chk,
		log.CloneAsChild("SyncStore"),
		clampTTLS}
}

// AccountMap dto for repo, json fields are short to save redis RAM, model isn't public
type AccountMap struct {
	MoenId        string `validate:"omitempty,uuid_rfc4122" json:"mId"`
	FloId         string `validate:"omitempty,uuid_rfc4122" json:"fId"`
	Issuer        string `validate:"omitempty,min=3,max=256" json:"iss,omitempty"`
	MoenAccountId string `validate:"omitempty,uuid_rfc4122" json:"mAcId,omitempty"`
	FloAccountId  string `validate:"omitempty,uuid_rfc4122" json:"fAcId,omitempty"`
}

func (acm *AccountMap) Normalize(v *Validator) (err error) {
	if acm == nil {
		err = errors.New("bounded object is nil")
	} else if acm.FloId == "" && acm.MoenId == "" {
		err = &HttpErr{400, "both moenId & floId are blank", false, nil}
	} else if err = v.Struct(acm); err == nil {
		acm.MoenId = strings.ToLower(acm.MoenId)
		acm.FloId = strings.ToLower(acm.FloId)
		acm.MoenAccountId = strings.ToLower(acm.MoenAccountId)
		acm.FloAccountId = strings.ToLower(acm.FloAccountId)
	}
	return
}

func (acm *AccountMap) NeedRepair() bool {
	//return acm != nil && acm.FloId != "" && acm.MoenId != "" && (acm.MoenAccountId == "" || acm.FloAccountId == "" || acm.Issuer == "")
	return acm != nil && acm.FloId != "" && acm.MoenId != "" && (acm.FloAccountId == "" || acm.Issuer == "")
}

func (acm *AccountMap) NeedFloAccIdRepair() bool {
	return acm != nil && acm.FloId != "" && acm.MoenId != "" && acm.FloAccountId == ""
}

func (acm AccountMap) String() string {
	return fmt.Sprintf("[moen:%s flo:%s]", acm.MoenId, acm.FloId)
}

func (acm *AccountMap) AsSyncDataRes() *SyncDataRes {
	if acm == nil {
		return nil
	}
	return &SyncDataRes{
		MoenId:    acm.MoenId,
		FloId:     acm.FloId,
		Issuer:    acm.Issuer,
		MoenAccId: acm.MoenAccountId,
		FloAccId:  acm.FloAccountId,
	}
}

func (acm *AccountMap) Clone() *AccountMap {
	if acm == nil {
		return nil
	}
	cp := *acm
	return &cp
}

func (a *syncStore) Check(ctx context.Context, moenId, floId string) (found bool, err error) {
	a.log.PushScope("Check", moenId, floId)
	defer a.log.PopScope()

	if res, e := a.GetMap(ctx, moenId, floId, ""); e != nil {
		err = e
	} else {
		found = res != nil
	}
	return
}

func (a *syncStore) GetByAccount(ctx context.Context, moeAccId, floAccId string, orPredicate bool) ([]*AccountMap, error) { //only use pg for this one
	if moeAccId == "" && floAccId == "" {
		return nil, a.log.Warn("GetByAccount: moenAccId or floAccId is required")
	}

	pr := NewSqlBuilder().Append(USR_SYNC_SELECT)
	defer pr.Close()
	if moeAccId != "" {
		pr.Append(" acc_id=$%v", pr.Arg(moeAccId))
	}
	if floAccId != "" {
		if pr.ArgsLen() > 0 {
			if orPredicate {
				pr.Append(" or")
			} else {
				pr.Append(" and")
			}
		}
		pr.Append(" flo_acc_id=$%v", pr.Arg(floAccId))
	}
	pr.Append(" order by created asc limit 500") //add optional skip later if needed, limit is added for system safety

	if rows, e := a.pg.Query(ctx, pr.String(), pr.Args()...); e != nil {
		return nil, a.log.IfErrorF(e, "GetByAccount: QUERY moeAcc=%v floAcc=%v", moeAccId, floAccId)
	} else {
		defer rows.Close()
		res := make([]*AccountMap, 0)
		for rows.Next() {
			ac := AccountMap{}
			if e = rows.Scan(&ac.MoenId, &ac.FloId, &ac.Issuer, &ac.MoenAccountId, &ac.FloId); e != nil {
				a.log.IfErrorF(e, "GetByAccount: SCAN moeAcc=%v floAcc=%v", moeAccId, floAccId)
			} else {
				res = append(res, &ac)
			}
		}
		if e != nil && len(res) != 0 {
			e = nil
		}
		return res, e
	}
}

func (a *syncStore) GetMap(ctx context.Context, moenId, floId, moenIssuer string) (found *AccountMap, err error) {
	a.log.PushScope("GetMap", moenId, floId)
	defer a.log.PopScope()

	chk := AccountMap{MoenId: moenId, FloId: floId, Issuer: moenIssuer}
	if err = chk.Normalize(a.valid); err != nil {
		a.log.IfWarnF(err, "Normalize validate")
	} else if res, _ := a.getRedis(ctx, &chk); res != nil {
		if res.MoenId != "" && res.FloId != "" {
			found = res //found in cache
			return
		} //else, found nil cache, do nothing
	}

	if found, err = a.getPg(ctx, &chk); found != nil {
		go a.putRedis(ctx, found) //write to cache
	} else {
		go a.putRedis(ctx, &chk)
	}
	return
}

const USR_SYNC_SELECT = `select id,flo_user,
			COALESCE(cast(issuer as text),'') as issuer,
			COALESCE(cast(acc_id as text),'') as acc_id,
			COALESCE(cast(flo_acc_id as text),'') as flo_acc_id 
		from cognito_user where `

func (a *syncStore) getPg(ctx context.Context, c *AccountMap) (found *AccountMap, err error) {
	var (
		rows *sql.Rows
		str  = _loggerSbPool.Get()
		args = make([]interface{}, 0)
	)
	defer _loggerSbPool.Put(str)
	str.WriteString(USR_SYNC_SELECT)
	if c.MoenId != "" {
		str.WriteString("id=$1")
		args = append(args, c.MoenId)
	} else {
		str.WriteString("flo_user=$1")
		args = append(args, c.FloId)
	}
	if c.Issuer != "" {
		str.WriteString(" and issuer=$2")
		args = append(args, c.Issuer)
	}

	query := str.String()
	if rows, err = a.pg.Query(ctx, query, args...); err != nil {
		a.log.IfErrorF(err, "getPg query %q", query)
	} else {
		defer rows.Close()
		if rows.Next() {
			ck := AccountMap{}
			if err = rows.Scan(&ck.MoenId, &ck.FloId, &ck.Issuer, &ck.MoenAccountId, &ck.FloAccountId); err != nil {
				a.log.IfErrorF(err, "getPg scan")
			} else {
				found = &ck
			}
		}
	}
	return
}

func (a *syncStore) getRedis(ctx context.Context, c *AccountMap) (found *AccountMap, err error) {
	key, val := a.redisKeys(c) //returns moenKey & floKey
	if c.FloId != "" {
		key = val //assign floKey to be used as redis key
	} //else use moenKey as redis key
	if val, err = a.redis.Get(ctx, key); err == redis.Nil {
		return //found nothing
	} else if vl := len(val); vl > 0 { //found something
		if vl > 8 && val[0] == '{' && val[vl-1] == '}' { //is json
			found = &AccountMap{}
			if unmarshalError := json.Unmarshal([]byte(val), found); unmarshalError != nil {
				a.log.IfWarnF(unmarshalError, "getRedis %s", key)
				found = nil //clear blank value
			}
		}
	} else { //regular error
		a.log.IfWarnF(err, "getRedis %s", key)
	}
	return
}

func (a *syncStore) Save(ctx context.Context, m *AccountMap) (err error) {
	a.log.PushScope("Save", m.MoenId, m.FloId)
	defer a.log.PopScope()

	if m == nil {
		err = a.log.Error("moenId is blank")
	} else if m.MoenId == "" {
		err = a.log.Error("moenId is blank")
	} else if m.FloId == "" {
		err = a.log.Error("floId is blank")
	} else {
		warn := make([]string, 0)
		if m.FloAccountId == "" {
			warn = append(warn, "floAccountId is blank")
		}
		if m.MoenAccountId == "" {
			warn = append(warn, "moenAccountId is blank")
		}
		if len(warn) > 0 {
			a.log.Warn(strings.Join(warn, ", "))
		}
		if err = m.Normalize(a.valid); err != nil {
			a.log.IfWarnF(err, "Normalize validation")
		} else if err = a.putPg(ctx, m); err == nil {
			go a.putRedis(ctx, m)
		}
	}
	return
}

func strOrNil(s string) interface{} {
	if s != "" {
		return s
	}
	return nil
}

func (a *syncStore) putPg(ctx context.Context, c *AccountMap) error {
	var (
		rows  int64 = 0
		query       = `insert into cognito_user (id,flo_user,issuer,acc_id,flo_acc_id)
			values ($1,$2,$3,$4,$5) 
			on conflict (flo_user,issuer) do update set acc_id=$4,flo_acc_id=$5`
		args = []interface{}{
			c.MoenId,
			c.FloId,
			c.Issuer,
			strOrNil(c.MoenAccountId),
			strOrNil(c.FloAccountId),
		}
	)
	if res, e := a.pg.ExecNonQuery(ctx, query, args...); e != nil {
		return a.log.IfErrorF(e, "putPg: exec %v", c)
	} else if rows, e = res.RowsAffected(); e != nil {
		return a.log.IfWarnF(e, "putPg: rows %v", c)
	} else {
		a.log.Debug("putPg: OK rows=%v | %v", rows, c)
	}
	return nil
}

func (a *syncStore) redisKeys(c *AccountMap) (moen, flo string) {
	moen = fmt.Sprintf("fl_mo:usr_m:{%s}:", c.MoenId)
	flo = fmt.Sprintf("fl_mo:usr_f:{%s}:", c.FloId)
	if a.log.isDebug {
		moen += "_"
		flo += "_"
	}
	return
}

func (a *syncStore) putRedis(ctx context.Context, c *AccountMap) error {
	defer panicRecover(a.log, "putRedis", c)
	var (
		moen, flo = a.redisKeys(c)
		es        = make([]error, 0)
		ttls      = a.expS
	)
	if c.MoenId != "" {
		if c.FloId == "" {
			ttls /= 10
		}
		if js, e := json.Marshal(c); e != nil {
			es = append(es, a.log.IfWarnF(e, "putRedis: moenK %s", moen))
			return wrapErrors(es)
		} else if _, e = a.redis.Set(ctx, moen, js, ttls); e != nil && e != redis.Nil {
			es = append(es, a.log.IfWarnF(e, "putRedis: moenK %s", moen))
		}
	}
	if c.FloId != "" {
		if c.MoenId == "" {
			ttls /= 10
		}
		if js, e := json.Marshal(c); e != nil {
			es = append(es, a.log.IfWarnF(e, "putRedis: floK %s", moen))
		} else if _, e = a.redis.Set(ctx, flo, js, ttls); e != nil && e != redis.Nil {
			es = append(es, a.log.IfWarnF(e, "putRedis: floK %s", flo))
		}
	}
	return wrapErrors(es)
}

func (a *syncStore) Remove(ctx context.Context, moenId, floId string) (err error) {
	a.log.PushScope("Remove", moenId, floId)
	defer a.log.PopScope()

	if moenId == "" && floId == "" {
		err = a.log.Warn("moenId & floId are both blank")
	} else {
		chk := AccountMap{MoenId: moenId, FloId: floId}
		if err = chk.Normalize(a.valid); err != nil {
			a.log.IfWarnF(err, "Normalize validation")
		} else {
			err = a.delPg(ctx, &chk)
			go a.delRedis(ctx, &chk)
		}
	}
	return
}

func (a *syncStore) delPg(ctx context.Context, c *AccountMap) error {
	var (
		predicate = make([]string, 0, 2)
		args      = make([]interface{}, 0, 2)
	)
	if c.MoenId != "" {
		predicate = append(predicate, fmt.Sprintf("id=$%v", len(predicate)+1))
		args = append(args, c.MoenId)
	}
	if c.FloId != "" {
		predicate = append(predicate, fmt.Sprintf("flo_user=$%v", len(predicate)+1))
		args = append(args, c.FloId)
	}
	if len(predicate) > 0 {
		query := fmt.Sprintf("delete from cognito_user where %v;", strings.Join(predicate, " and "))
		if _, e := a.pg.ExecNonQuery(ctx, query, args...); e != nil {
			return a.log.IfErrorF(e, "delPg")
		}
	}
	return nil
}

func (a *syncStore) delRedis(ctx context.Context, c *AccountMap) {
	defer panicRecover(a.log, "delRedis", c)
	moen, flo := a.redisKeys(c)
	if c.MoenId != "" {
		if _, e := a.redis.Delete(ctx, moen); e != nil && e != redis.Nil {
			a.log.IfWarnF(e, "delRedis: %v", moen)
		}
	}
	if c.FloId != "" {
		if _, e := a.redis.Delete(ctx, flo); e != nil && e != redis.Nil {
			a.log.IfWarnF(e, "delRedis: %v", flo)
		}
	}
}
