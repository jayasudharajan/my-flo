package main

import (
	"database/sql"
	"time"
)

type entityStore struct {
	log Log
	chk Validator
	pg  Postgres
}

type EntityStore interface {
	Ping() error
	Save(usr *LinkedUser) (bool, error)
	Get(usrId string, sync bool) (*LinkedUser, error)
	Delete(usrId string) (bool, error)
}

// CreateEntityStore stateless instance
func CreateEntityStore(log Log, chk Validator, pg Postgres) EntityStore {
	return &entityStore{log, chk, pg}
}

// Ping ensure schema exists
func (re *entityStore) Ping() error {
	re.log.PushScope("Ping")
	defer re.log.PopScope()

	const pingQuery = "select flo_user_id from adc_user_registry limit 0;"
	if rows, e := re.pg.Query(pingQuery); e != nil {
		return re.log.IfErrorF(e, "query")
	} else {
		defer rows.Close()
		if rows.Next() {
			return re.log.IfErrorF(rows.Err(), "read")
		} else {
			return nil
		}
	}
}

type LinkedUser struct {
	UserId   string    `json:"flo_user_id" validate:"uuid4_rfc4122,required"`
	ClientId string    `json:"flo_client_id" validate:"min=8,max=64,required"`
	Version  int32     `json:"version,omitempty" validate:"min=0,omitempty"`
	Updated  time.Time `json:"updated,omitempty"`
	Created  time.Time `json:"created,omitempty"`
}

func (lu *LinkedUser) Clone() *LinkedUser {
	if lu == nil {
		return nil
	}
	cp := *lu  //make a copy
	return &cp //ptr to the copy
}

func (lu LinkedUser) String() string {
	return tryToJson(lu)
}

func (re *entityStore) Save(usr *LinkedUser) (modified bool, err error) {
	re.log.PushScope("Save")
	defer re.log.PopScope()

	if err = re.chk.Struct(usr); err != nil {
		re.log.IfWarn(err)
	} else {
		const stmt = `insert into adc_user_registry (flo_user_id,flo_client_id,version) values($1,$2,$3) 
					on conflict (flo_user_id) do 
						update set flo_client_id=$2,version=$3,updated=current_timestamp
							returning updated,created;`
		var rows *sql.Rows
		if rows, err = re.pg.Query(stmt, usr.UserId, usr.ClientId, usr.Version); err != nil {
			re.log.IfErrorF(err, "Query: %v", usr)
		} else {
			defer rows.Close()
			if rows.Next() {
				if err = rows.Scan(&usr.Updated, &usr.Created); err != nil {
					re.log.IfErrorF(err, "Scan: usrId=%v", usr.UserId)
				} else {
					modified = !usr.Created.Truncate(time.Second).Equal(usr.Updated.Truncate(time.Second))
					re.log.Trace("OK | %v", usr)
				}
			} else {
				re.log.Notice("EMPTY | %v", usr)
			}
		}
	}
	return
}

const validUuid = "uuid4_rfc4122,required"

func (re *entityStore) Get(usrId string, _ bool) (usr *LinkedUser, e error) {
	if e = re.chk.Value(usrId, validUuid, "usrId"); e != nil {
		return
	}
	re.log.PushScope("Get", usrId)
	defer re.log.PopScope()

	const selStmt = "select flo_client_id,version,updated,created from adc_user_registry where flo_user_id=$1;"
	var rows *sql.Rows
	if rows, e = re.pg.Query(selStmt, usrId); e != nil {
		re.log.IfErrorF(e, "query")
	} else {
		defer rows.Close()
		if rows.Next() {
			var (
				u   = LinkedUser{UserId: usrId}
				ver sql.NullInt32
			)
			if e = rows.Scan(&u.ClientId, &ver, &u.Updated, &u.Created); e != nil {
				re.log.IfWarnF(e, "scan")
			} else {
				if ver.Valid {
					u.Version = ver.Int32
				}
				usr = &u //assign return ref
				re.log.Trace("OK")
			}
		} else {
			re.log.Trace("EMPTY")
		}
	}
	return
}

func (re *entityStore) Delete(usrId string) (modified bool, err error) {
	if err = re.chk.Value(usrId, validUuid, "usrId"); err != nil {
		re.log.IfWarnF(err, "Delete: %q", usrId)
		return
	}
	re.log.PushScope("Del", usrId)
	defer re.log.PopScope()

	const rmStmt = "delete from adc_user_registry where flo_user_id=$1;"
	var sr sql.Result
	if sr, err = re.pg.ExecNonQuery(rmStmt, usrId); err != nil {
		re.log.IfError(err)
	} else {
		count, _ := sr.RowsAffected()
		modified = count > 0
		re.log.Trace("OK | rowsMod=%v", count)
	}
	return
}
