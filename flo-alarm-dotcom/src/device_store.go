package main

import (
	"database/sql"
	"fmt"
	"strings"
)

type DeviceStore interface {
	Ping() error

	GetById(deviceId string, sync bool) (*LinkedDevice, error)
	GetByMac(mac string, sync bool) (*LinkedDevice, error)
	GetByUserId(userId string, sync bool) ([]*LinkedDevice, error)
	Save(devices ...*LinkedDevice) error
	DeleteById(deviceId string) error
	DeleteByUserId(userId string) error
}

type LinkedDevice struct {
	Id     string `json:"id" validate:"uuid4_rfc4122,required"`
	Mac    string `json:"mac" validate:"hexadecimal,len=12,required"`
	UserId string `json:"user_id" validate:"uuid4_rfc4122,required"`
	LocId  string `json:"loc_id" validate:"uuid4_rfc4122,required"`
}

func (d *LinkedDevice) Normalize() *LinkedDevice {
	if d != nil {
		d.Mac = strings.ToLower(strings.ReplaceAll(d.Mac, ":", ""))
		d.Id = strings.ToLower(d.Id)
	}
	return d
}

func (d *LinkedDevice) Clone() *LinkedDevice {
	if d == nil {
		return nil
	}
	cp := *d   //copy
	return &cp //return ref to copy
}

func (d LinkedDevice) String() string {
	return fmt.Sprintf("did=%v:%v", d.Id, d.Mac)
}

func CreateDeviceStore(pg Postgres, chk Validator, log Log) DeviceStore {
	return &deviceStore{pg, chk, log}
}

type deviceStore struct {
	pg  Postgres
	chk Validator
	log Log
}

func (ds *deviceStore) Ping() (e error) {
	const stmt = "select id,mac from adc_device limit 0;"
	if _, e = ds.pg.ExecNonQuery(stmt); e != nil {
		ds.log.IfErrorF(e, "ping")
	}
	return
}

func (ds *deviceStore) GetById(deviceId string, sync bool) (device *LinkedDevice, e error) {
	if e = ds.chk.Value(deviceId, validUuid, "deviceId"); e != nil {
		return
	}
	ds.log.PushScope("Get_id", deviceId)
	defer ds.log.PopScope()

	const stmt = "select mac,user_id,loc_id from adc_device where id=$1;"
	var rows *sql.Rows
	if rows, e = ds.pg.Query(stmt, deviceId); e != nil {
		ds.log.IfErrorF(e, "query")
	} else {
		defer rows.Close()
		if rows.Next() {
			d := LinkedDevice{Id: deviceId}
			if e = rows.Scan(&d.Mac, &d.UserId, &d.LocId); e != nil {
				ds.log.IfWarnF(e, "scan")
			} else {
				device = d.Normalize() //normalize & assign return ref
				ds.log.Trace("OK")
			}
		} else {
			ds.log.Trace("EMPTY")
		}
	}
	return
}

const validMac = "hexadecimal,len=12,required"

func (ds *deviceStore) GetByMac(mac string, sync bool) (device *LinkedDevice, e error) {
	if e = ds.chk.Value(mac, validMac, "mac"); e != nil {
		return
	}
	ds.log.PushScope("Get_mac", mac)
	defer ds.log.PopScope()

	const stmt = "select id,user_id,loc_id from adc_device where mac=$1;"
	var rows *sql.Rows
	if rows, e = ds.pg.Query(stmt, mac); e != nil {
		ds.log.IfErrorF(e, "query")
	} else {
		defer rows.Close()
		if rows.Next() {
			d := LinkedDevice{Mac: mac}
			if e = rows.Scan(&d.Id, &d.UserId, &d.LocId); e != nil {
				ds.log.IfWarnF(e, "scan")
			} else {
				device = d.Normalize() //normalize & assign return ref
				ds.log.Trace("OK")
			}
		} else {
			ds.log.Trace("EMPTY")
		}
	}
	return
}

func (ds *deviceStore) GetByUserId(userId string, sync bool) (res []*LinkedDevice, e error) {
	if e = ds.chk.Value(userId, validUuid, "userId"); e != nil {
		return
	}
	ds.log.PushScope("Get_usr", userId)
	defer ds.log.PopScope()

	const stmt = "select id,mac,loc_id from adc_device where user_id=$1;"
	var rows *sql.Rows
	if rows, e = ds.pg.Query(stmt, userId); e != nil {
		ds.log.IfErrorF(e, "query")
	} else {
		defer rows.Close()
		for rows.Next() {
			d := LinkedDevice{UserId: userId}
			if e = rows.Scan(&d.Id, &d.Mac, &d.LocId); e != nil {
				ds.log.IfWarnF(e, "scan")
			} else {
				res = append(res, d.Normalize()) //normalize & assign return ref
			}
		}
		if rl := len(res); rl == 0 {
			ds.log.Trace("EMPTY")
		} else {
			ds.log.Trace("OK. Found=%v", rl)
		}
	}
	return
}

type devSqlArr struct { //device sql array
	Devices []*LinkedDevice `json:"devices" validate:"min=1,dive,required"`
}

func (b *devSqlArr) Normalize() *devSqlArr {
	if b != nil {
		for _, dv := range b.Devices {
			dv.Normalize()
		}
	}
	return b
}
func (b devSqlArr) String() string {
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	sb.WriteString("[")
	tail := len(b.Devices) - 1
	for i, d := range b.Devices {
		sb.WriteString(d.Id)
		if i < tail {
			sb.WriteString(",")
		}
	}
	sb.WriteString("]")
	return sb.String()
}
func (b *devSqlArr) SqlUpsert() string {
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	//maybe: https://stackoverflow.com/questions/34514457/bulk-insert-update-if-on-conflict-bulk-upsert-on-postgres
	sb.WriteString("insert into adc_device (id,mac,user_id,loc_id) values \n")
	tail := len(b.Devices) - 1
	for i, d := range b.Devices {
		sb.WriteString(fmt.Sprintf("\t('%s','%s','%s','%s')", d.Id, d.Mac, d.UserId, d.LocId))
		if i < tail {
			sb.WriteString(",")
		}
		sb.WriteString("\n")
	}
	sb.WriteString("on conflict (id) do nothing;")
	return sb.String()
}

func (ds *deviceStore) Save(devices ...*LinkedDevice) (e error) {
	batch := devSqlArr{devices}
	ds.log.PushScope("Save", batch.String())
	defer ds.log.PopScope()

	if e = ds.chk.Struct(batch.Normalize()); e != nil {
		ds.log.IfWarnF(e, "validate")
		return
	}
	var (
		stmt = batch.SqlUpsert()
		sr   sql.Result
	)
	if sr, e = ds.pg.ExecNonQuery(stmt); e != nil {
		ds.log.IfErrorF(e, "exec")
	} else {
		count, _ := sr.RowsAffected()
		ds.log.Trace("OK | rowsMod=%v", count)
	}
	return
}

func (ds *deviceStore) DeleteById(deviceId string) (e error) {
	if e = ds.chk.Value(deviceId, validUuid, "deviceId"); e != nil {
		return
	}
	ds.log.PushScope("Del_id", deviceId)
	defer ds.log.PopScope()

	const stmt = "delete from adc_device where id=$1;"
	var sr sql.Result
	if sr, e = ds.pg.ExecNonQuery(stmt, deviceId); e != nil {
		ds.log.IfErrorF(e, "exec")
	} else {
		count, _ := sr.RowsAffected()
		ds.log.Trace("OK | rowsMod=%v", count)
	}
	return
}

func (ds *deviceStore) DeleteByUserId(usrId string) (e error) {
	if e = ds.chk.Value(usrId, validUuid, "usrId"); e != nil {
		return
	}
	ds.log.PushScope("Del_usr", usrId)
	defer ds.log.PopScope()

	const stmt = "delete from adc_device where user_id=$1;"
	var sr sql.Result
	if sr, e = ds.pg.ExecNonQuery(stmt, usrId); e != nil {
		ds.log.IfErrorF(e, "exec")
	} else {
		count, _ := sr.RowsAffected()
		ds.log.Trace("OK | rowsMod=%v", count)
	}
	return
}
