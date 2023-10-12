package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis"
)

type entityStore struct {
	logger  *Logger
	redis   *RedisConnection
	pgSql   *PgSqlDb
	evtExpS int
	keyDur  KeyPerDuration
}

var (
	_entityStoreKeyDur    = CreateKeyPerDuration(time.Hour * 12) //static singleton
	_entityStoreRedisExpS = defaultExpirationAsyncResponse
)

func init() {
	if exp, _ := strconv.Atoi(getEnvOrDefault("FLO_EXPIRATION_ASYNC_RESPONSE_SECONDS", "")); exp > 0 {
		_entityStoreRedisExpS = exp
	}
}

type EntityStore interface {
	GetDeviceIdByMac(ctx context.Context, macAddress string) (string, error)
	GetDeviceMacById(ctx context.Context, deviceId string) (string, error)
	DeviceExists(ctx context.Context, deviceId, macAddress string) (bool, error)
	// StoreDevices Store immutable deviceId & macAddress registrations only
	StoreDevices(ctx context.Context, devices ...*Device) error
	// DeleteDevices Remove immutable deviceId & macAddress registrations
	DeleteDevices(ctx context.Context, devices ...*Device) (int64, error)

	// StoreUser Store immutable userId registration only
	StoreUser(ctx context.Context, userId string) error
	UserExists(ctx context.Context, userId string) (bool, error)
	DeleteUser(ctx context.Context, userId string) error

	StoreEvent(ctx context.Context, message *EventMessage) error
	GetEvent(ctx context.Context, messageId string) (*EventMessage, error)
	GetEventsByDevice(ctx context.Context, deviceId string, limit int32) ([]*EventMessage, error)

	StoreDirective(ctx context.Context, message *DirectiveMessage) error
	GetDirective(ctx context.Context, messageId string) (*DirectiveMessage, error)

	ScanDevices(ctx context.Context, mac string, limit int32) ([]*ScanDevice, error)
	ScanUsers(ctx context.Context, id string, limit int32) ([]*ScanUser, error)
	LogDeviceCleaned(ctx context.Context, id, mac string) error
}

const deviceIdKeyFormat = "ring.device.id.{%s}"
const deviceMacAddressKeyFormat = "ring.device.mac.{%s}"
const userKeyFormat = "ring.user.{%s}"
const directiveKeyFormat = "ring.directive.{%s}"
const eventKeyFormat = "ring.event.{%s}"
const defaultExpirationAsyncResponse = 60 * 60 * 24 // 24h

// CreateEntityStore stateless instance
func CreateEntityStore(logger *Logger, redis *RedisConnection, pg *PgSqlDb) EntityStore {
	es := entityStore{
		logger:  logger.CloneAsChild("entityStore"),
		redis:   redis,
		pgSql:   pg,
		evtExpS: _entityStoreRedisExpS,
		keyDur:  _entityStoreKeyDur,
	}
	return &es
}

func (es *entityStore) GetDeviceIdByMac(ctx context.Context, macAddress string) (did string, err error) {
	k := es.buildDeviceMacKey(macAddress)
	if did, err = es.redis.Get(ctx, k); err != nil {
		if err != redis.Nil { //warn
			err = es.logger.IfWarnF(err, "GetDeviceIdByMac: (redis) %v", k)
		} else if did, err = es.getDeviceIdPg(macAddress); err == nil { //missing from redis & no err from pg
			go es.storeDevicesRedis(ctx, did, macAddress, false) //did maybe missing but OK, will reduce pg hits
		}
	}
	return
}

func (es *entityStore) getDeviceIdPg(mac string) (did string, err error) {
	const sql = `SELECT id FROM device_registry WHERE mac=$1 LIMIT 1;`
	if rows, e := es.pgSql.Connection.Query(sql, strings.ToLower(mac)); e != nil {
		err = es.logger.IfErrorF(e, "getDeviceIdPg: query %v", mac)
	} else {
		defer rows.Close()
		if rows.Next() {
			if e = rows.Scan(&did); e != nil {
				err = es.logger.IfErrorF(e, "getDeviceIdPg: scan %v", mac)
			}
		}
	}
	return
}

func (es *entityStore) GetDeviceMacById(ctx context.Context, deviceId string) (mac string, err error) {
	k := es.buildDeviceIdKey(deviceId)
	if mac, err = es.redis.Get(ctx, k); err != nil {
		if err != redis.Nil { //warn
			err = es.logger.IfWarnF(err, "GetDeviceMacById: (redis) %v", k)
		} else if mac, err = es.getDeviceMacPg(deviceId); err == nil { //missing from redis & no err from pg
			go es.storeDevicesRedis(ctx, deviceId, mac, false) //mac maybe missing but OK, will reduce pg hits
		}
	}
	return
}

func (es *entityStore) getDeviceMacPg(did string) (mac string, err error) {
	const sql = `SELECT mac FROM device_registry WHERE id=$1;`
	if rows, e := es.pgSql.Connection.Query(sql, strings.ToLower(did)); e != nil {
		err = es.logger.IfErrorF(e, "getDeviceMacPg: query %v", did)
	} else {
		defer rows.Close()
		if rows.Next() {
			if e = rows.Scan(&mac); e != nil {
				err = es.logger.IfErrorF(e, "getDeviceMacPg: scan %v", did)
			} else {
				mac = strings.ReplaceAll(mac, ":", "")
			}
		}
	}
	return
}

func (es *entityStore) DeviceExists(ctx context.Context, deviceId, macAddress string) (bool, error) {
	if deviceId != "" {
		mac, e := es.GetDeviceMacById(ctx, deviceId)
		return mac != "", e
	} else if macAddress != "" {
		id, e := es.GetDeviceIdByMac(ctx, macAddress)
		return id != "", e
	} else {
		return false, errors.New("at least 1 input is required")
	}
}

func (es *entityStore) StoreDevices(ctx context.Context, devices ...*Device) error {
	errArr := make([]error, 0)
	const sql = `INSERT INTO device_registry (id,mac) VALUES($1,$2) ON CONFLICT (id) DO NOTHING;`
	for _, d := range devices {
		if r, e := es.pgSql.Connection.Exec(sql, strings.ToLower(d.Id), strings.ToLower(d.MacAddress)); e != nil {
			errArr = append(errArr, es.logger.IfErrorF(e, "StoreDevices: (PG) %v - %v", d.Id, d.MacAddress))
		} else {
			es.logger.Debug("StoreDevices: (PG) OK %v - %v", d.Id, d.MacAddress)
			if n, _ := r.RowsAffected(); n > 0 {
				go es.storeDevicesRedis(ctx, d.Id, d.MacAddress, true)
			}
		}
	}
	return wrapErrors(errArr)
}

func (es *entityStore) storeDevicesRedis(ctx context.Context, did, mac string, force bool) {
	defer panicRecover(es.logger, "storeDevicesRedis: %v - %v", did, mac)

	const keyTTL = time.Hour
	var (
		isMissing = did == "" || mac == ""
		exp       = int(keyTTL.Seconds())
	)
	if !isMissing {
		exp = exp * 30
	}
	if mac != "" {
		if k := es.buildDeviceMacKey(mac); force || es.keyDur.Check(fmt.Sprintf("%s->%v", k, did), keyTTL) { //check to reduce writes
			if _, err := es.redis.Set(ctx, k, strings.ToLower(did), exp); err != nil {
				es.logger.IfWarnF(err, "storeDevicesRedis: failed %v -> %q", k, did)
			} else {
				if did == "" {
					es.logger.Debug("storeDevicesRedis: OK %v STORE_EMPTY", k)
				} else {
					es.logger.Debug("storeDevicesRedis: OK %v -> %q", k, did)
				}
			}
		}
	}
	if did != "" {
		if k := es.buildDeviceIdKey(did); force || es.keyDur.Check(fmt.Sprintf("%s->%v", k, mac), keyTTL) {
			if _, err := es.redis.Set(ctx, k, strings.ToLower(mac), exp); err != nil {
				es.logger.IfWarnF(err, "storeDevicesRedis: failed %v -> %q", k, did)
			} else {
				if mac == "" {
					es.logger.Debug("storeDevicesRedis: OK %v STORE_EMPTY", k)
				} else {
					es.logger.Debug("storeDevicesRedis: OK %v -> %q", k, mac)
				}
			}
		}
	}
}

func (es *entityStore) DeleteDevices(ctx context.Context, devices ...*Device) (int64, error) {
	var (
		totalCount int64
		errArr     = make([]error, 0)
	)
	for _, d := range devices {
		go es.deleteDevicesRedis(ctx, d.Id, d.MacAddress) //rm redis no matter what

		var (
			sql  = "DELETE FROM device_registry "
			args = make([]interface{}, 0, 2)
		)
		if d.Id != "" && d.MacAddress != "" {
			sql += " WHERE id=$1 AND mac=$2;"
			args = append(args, d.Id, d.MacAddress)
		} else if d.Id != "" {
			sql += " WHERE id=$1;"
			args = append(args, d.Id)
		} else if d.MacAddress != "" {
			sql += " WHERE mac=$1;"
			args = append(args, d.MacAddress)
		} else {
			continue
		}

		if res, e := es.pgSql.Connection.ExecContext(ctx, sql, args...); e != nil {
			errArr = append(errArr, es.logger.IfErrorF(e, "DeleteDevices: (PG) query %v - %v", d.Id, d.MacAddress))
		} else if n, e := res.RowsAffected(); e != nil {
			errArr = append(errArr, es.logger.IfWarnF(e, "DeleteDevices: (PG) scan %v - %v", d.Id, d.MacAddress))
		} else if n > 0 {
			totalCount++
		}
	}
	return totalCount, wrapErrors(errArr)
}

func (es *entityStore) deleteDevicesRedis(ctx context.Context, did, mac string) {
	defer panicRecover(es.logger, "deleteDevicesRedis: %v - %v", did, mac)

	var (
		didKey = es.buildDeviceIdKey(did)
		macKey = es.buildDeviceMacKey(mac)
	)
	if _, err := es.redis.Delete(ctx, didKey); err != nil && err != redis.Nil {
		es.logger.IfWarnF(err, "deleteDevicesRedis: %v", did)
	} else if _, err = es.redis.Delete(ctx, macKey); err != nil && err != redis.Nil {
		es.logger.IfWarnF(err, "deleteDevicesRedis: %v", mac)
	} else {
		es.keyDur.Clear(fmt.Sprintf("%s->%v", macKey, did))
		es.keyDur.Clear(fmt.Sprintf("%s->%v", didKey, mac))
		es.logger.Debug("deleteDevicesRedis: OK %v - %v", did, mac)
	}
}

func (es *entityStore) StoreUser(ctx context.Context, userId string) error {
	const sql = `INSERT INTO user_registry (id) VALUES($1) ON CONFLICT (id) DO NOTHING;` //don't throw if already exists
	if res, e := es.pgSql.Connection.Exec(sql, strings.ToLower(userId)); e != nil {
		return es.logger.IfErrorF(e, "StoreUser: (PG) %v", userId)
	} else if rows, _ := res.RowsAffected(); rows > 0 { //initial insert
		go es.storeUserRedis(ctx, userId, true)
	}
	es.logger.Debug("StoreUser: (PG) OK %v", userId)
	return nil
}

func (es *entityStore) storeUserRedis(ctx context.Context, userId string, exists bool) {
	defer panicRecover(es.logger, "storeUserRedis: %v", userId)

	//if k := es.buildUserKey(userId); es.keyDur.Check(fmt.Sprintf("%s=%v", k, exists), DUR_1_DAY) {
	k := es.buildUserKey(userId)
	{
		exp := int(DUR_1_DAY.Seconds())
		if exists {
			exp = exp * 30 //much longer cache
		}
		if _, err := es.redis.Set(ctx, k, IfTrue(exists, 1, 0), exp); err != nil {
			es.logger.IfWarnF(err, "storeUserRedis: failed %v -> %v", k, exists)
		} else {
			es.logger.Debug("storeUserRedis: OK %v -> %v", k, exists)
		}
	}
}

func (es *entityStore) DeleteUser(ctx context.Context, userId string) error {
	go es.deleteUserRedis(ctx, userId)

	const sql = `DELETE FROM user_registry WHERE id=$1;`
	if _, e := es.pgSql.ExecNonQuery(ctx, sql, userId); e != nil {
		return es.logger.IfErrorF(e, "DeleteUser: (PG) %v", userId)
	}
	return nil
}

func (es *entityStore) deleteUserRedis(ctx context.Context, userId string) {
	defer panicRecover(es.logger, "deleteUserRedis: %v", userId)

	k := es.buildUserKey(userId)
	if _, e := es.redis.Delete(ctx, k); e != nil && e != redis.Nil {
		es.logger.IfErrorF(e, "deleteUserRedis: %v", userId)
	}
}

func (es *entityStore) UserExists(ctx context.Context, userId string) (ok bool, err error) {
	if ok, err = es.userExistsRedis(ctx, userId); err != nil {
		if err == redis.Nil { //does not exists in redis
			if ok, err = es.userExistsPg(userId); err == nil { //exists in pg but not redis!
				go es.storeUserRedis(ctx, userId, ok) //save back to redis
			}
		}
	}
	return
}

func (es *entityStore) userExistsRedis(ctx context.Context, userId string) (bool, error) {
	k := es.buildUserKey(userId)
	if str, e := es.redis.Get(ctx, k); e == nil && str != "" {
		if str == "1" {
			return true, nil
		}
	} else if e != nil {
		if e == redis.Nil {
			return false, e //return as is on purpose
		}
		return false, es.logger.IfErrorF(e, "userExistsRedis: %v", k)
	}
	return false, nil
}

func (es *entityStore) userExistsPg(userId string) (bool, error) {
	var (
		sql       = `SELECT true FROM user_registry WHERE id=$1;` //return 1 bit to save i/o
		rows, err = es.pgSql.Connection.Query(sql, strings.ToLower(userId))
		ok        *bool
	)
	if err != nil {
		return false, es.logger.IfErrorF(err, "userExistsPg: query %v", userId)
	} else {
		defer rows.Close()
	}

	if !rows.Next() {
		return false, nil
	} else if err = rows.Scan(&ok); err != nil {
		return false, es.logger.IfErrorF(err, "userExistsPg: scan %v", userId)
	} else if ok == nil {
		return false, nil
	} else {
		return *ok, nil
	}
}

func (es *entityStore) GetEventsByDevice(ctx context.Context, deviceId string, limit int32) ([]*EventMessage, error) {
	if limit <= 0 {
		limit = 10
	} else if limit > 1_000 {
		limit = 1_000
	}
	var (
		res         = make([]*EventMessage, 0, limit)
		err         = make([]error, 0)
		cur         = time.Now().UTC()
		end         = cur.Add(-DUR_1_DAY * 2)
		found int32 = 0
	)
	for cur.After(end) && found < limit {
		key := es.getDeviceIdKey(deviceId, cur)
		//TODO: page til the end
		if arr, e := es.getEventsByDeviceKey(ctx, key, 0, limit); e != nil {
			err = append(err, e)
		} else if len(arr) > 0 {
			res = append(res, arr...)
			//limit -= int32(len(res))
			//if limit < 0 {
			//	res = res[:len(res)+int(limit)]
			//}
			found += int32(len(res))
			if found > limit {
				res = res[:limit]
			}
		}
		cur = cur.Add(-DUR_1_DAY)
	}
	return res, wrapErrors(err)
}

func (es *entityStore) jsonOrGzUnmarshal(s string, o interface{}) error {
	if sl := len(s); sl < 64 {
		return errors.New("jsonOrGzUnmarshal: buffer too short")
	} else if s[0] == '{' && s[sl-1] == '}' { //json for backward compatibility
		return json.Unmarshal([]byte(s), o)
	}
	return jsonUnMarshalGz([]byte(s), o) //json.gz
}

func (es *entityStore) getEventsByDeviceKey(ctx context.Context, key string, skip, limit int32) ([]*EventMessage, error) {
	var (
		res  = make([]*EventMessage, 0, limit)
		errs = make([]error, 0)
		cmd  = es.redis._client.LRange(ctx, key, int64(skip), int64(skip+limit-1))
	)
	if arr, e := cmd.Result(); e != nil && e != redis.Nil {
		es.logger.IfErrorF(e, "getEventsByDeviceKey: fetch %s %v", key, limit)
		errs = append(errs, e)
	} else if len(arr) > 0 {
		for _, s := range arr {
			if sl := len(s); sl < 64 {
				continue
			}
			em := EventMessage{}
			if e = es.jsonOrGzUnmarshal(s, &em); e != nil {
				es.logger.IfWarnF(e, "getEventsByDeviceKey: unmarshal %s %v", key, limit)
				errs = append(errs, e)
			} else {
				res = append(res, &em)
			}
		}
	}
	return res, wrapErrors(errs)
}

func (es *entityStore) getDeviceIdKey(deviceId string, dt time.Time) string {
	var (
		ts  = dt.UTC().Truncate(DUR_1_DAY).Format("060102")
		key = strings.ToLower(fmt.Sprintf("ring.event.did:%s:%s", deviceId, ts))
	)
	key = AppendKeyBranch(key, _commitBranch, es.logger.isDebug)
	return key
}

func (es *entityStore) getDeviceMessageKeys(m *EventMessage) []string {
	ids := m.Event.GetEndpointIds()
	if idLen := len(ids); idLen != 0 {
		keys := make([]string, 0, idLen)
		for _, id := range ids {
			keys = append(keys, es.getDeviceIdKey(id, time.Now().UTC()))
		}
		return keys
	}
	return nil
}

func (es *entityStore) storeEventByDevice(ctx context.Context, m *EventMessage) {
	defer panicRecover(es.logger, "storeEventByDevice: %v", m)

	keys := es.getDeviceMessageKeys(m)
	if len(keys) != 0 {
		if buf, e := jsonMarshalGz(m); e != nil {
			es.logger.IfWarnF(e, "storeEventByDevice: serialize %v", m.Event.Header.MessageId)
		} else {
			for _, key := range keys {
				if key == "" {
					continue
				}
				cmd := es.redis._client.LPush(ctx, key, buf)
				if e = cmd.Err(); e != nil {
					es.logger.IfWarnF(e, "storeEventByDevice: store %v", m.Event.Header.MessageId)
				} else if es.keyDur.Check(key, DUR_4_HRS) {
					if _, e = es.redis.Expire(ctx, key, _entityStoreRedisExpS); e != nil { //periodic TTL
						es.logger.IfWarnF(e, "storeEventByDevice: ttl %v", m.Event.Header.MessageId)
					}
				}
			}
		}
	}
}

func (es *entityStore) StoreEvent(ctx context.Context, m *EventMessage) error {
	var (
		key      = es.buildEventKey(m.Event.Header.MessageId)
		buf, err = jsonMarshalGz(m)
	)
	if err != nil {
		return fmt.Errorf("storeEvent: error while marshaling event for message %s - %v", m.Event.Header.MessageId, err)
	}

	_, err = es.redis.Set(ctx, key, buf, es.evtExpS)
	if es.logger.isDebug {
		es.storeEventByDevice(ctx, m)
	} else {
		go es.storeEventByDevice(ctx, m)
	}
	if err != nil {
		return fmt.Errorf("storeEvent: error while storing event for message %s - %v", m.Event.Header.MessageId, err)
	}

	es.logger.Trace("StoreEvent: OK %v", key)
	return nil
}

func (es *entityStore) GetEvent(ctx context.Context, messageId string) (*EventMessage, error) {
	var (
		e        EventMessage
		key      = es.buildEventKey(messageId)
		buf, err = es.redis.Get(ctx, key)
	)
	if err != nil {
		if err == redis.Nil {
			return nil, nil
		}
		return nil, fmt.Errorf("getEvent: error while retrieving event for message  %s - %v", messageId, err)
	}
	err = es.jsonOrGzUnmarshal(buf, &e)
	if err != nil {
		return nil, fmt.Errorf("getEvent: error while unmarshaling event for message  %s - %v", messageId, err)
	}
	return &e, nil
}

func (es *entityStore) StoreDirective(ctx context.Context, m *DirectiveMessage) error {
	defer panicRecover(es.logger, "storeDirective: %s", m.Directive.Header.MessageId)
	var (
		key      = es.buildDirectiveKey(m.Directive.Header.MessageId)
		buf, err = jsonMarshalGz(m)
	)
	if err != nil {
		return fmt.Errorf("storeDirective: error while marshaling directive for message  %s - %v", m.Directive.Header.MessageId, err)
	}
	_, err = es.redis.Set(ctx, key, buf, es.evtExpS)
	if err != nil {
		return fmt.Errorf("storeDirective: error while storing directive for message  %s - %v", m.Directive.Header.MessageId, err)
	}
	return nil
}

func (es *entityStore) GetDirective(ctx context.Context, messageId string) (*DirectiveMessage, error) {
	var (
		d        DirectiveMessage
		key      = es.buildDirectiveKey(messageId)
		buf, err = es.redis.Get(ctx, key)
	)
	if err != nil {
		if err == redis.Nil {
			return nil, nil
		}
		return nil, fmt.Errorf("getDirective: error while retrieving directive for message %s - %v", messageId, err)
	}
	err = es.jsonOrGzUnmarshal(buf, &d)
	if err != nil {
		return nil, fmt.Errorf("getDirective: error while unmarshaling directive for message  %s - %v", messageId, err)
	}
	return &d, nil
}

func (es *entityStore) buildUserKey(userId string) string {
	return strings.ToLower(fmt.Sprintf(userKeyFormat, userId))
}

func (es *entityStore) buildDeviceIdKey(deviceId string) string {
	return strings.ToLower(fmt.Sprintf(deviceIdKeyFormat, deviceId))
}

func (es *entityStore) buildDeviceMacKey(macAddress string) string {
	return strings.ToLower(fmt.Sprintf(deviceMacAddressKeyFormat, macAddress))
}

func (es *entityStore) buildEventKey(id string) string {
	key := strings.ToLower(fmt.Sprintf(eventKeyFormat, id))
	key = AppendKeyBranch(key, _commitBranch, es.logger.isDebug)
	return key
}

func (es *entityStore) buildDirectiveKey(id string) string {
	key := strings.ToLower(fmt.Sprintf(directiveKeyFormat, id))
	key = AppendKeyBranch(key, _commitBranch, es.logger.isDebug)
	return key
}

const SCAN_MAX = 1_000

func (es *entityStore) ScanDevices(ctx context.Context, mac string, limit int32) ([]*ScanDevice, error) {
	if limit > SCAN_MAX {
		limit = SCAN_MAX
	}
	if mac == "" {
		mac = "000000000000"
	}
	const sql = "select id,mac,created from device_registry where mac > $1 order by mac asc limit $2;"
	rows, err := es.pgSql.Query(ctx, sql, mac, limit)
	if err != nil {
		return nil, es.logger.IfErrorF(err, "ScanDevices Query: %v %v", mac, limit)
	}
	defer rows.Close()
	var (
		res  = make([]*ScanDevice, 0)
		oops = make([]error, 0)
	)
	for rows.Next() {
		d := ScanDevice{}
		if e := rows.Scan(&d.Id, &d.Mac, &d.Created); e != nil {
			oops = append(oops, e)
		} else if d.Id != "" {
			d.Mac = strings.ReplaceAll(d.Mac, ":", "")
			res = append(res, &d)
		}
	}
	return res, es.logger.IfWarnF(wrapErrors(oops), "ScanDevices Scan: %v %v", mac, limit)
}

func (es *entityStore) ScanUsers(ctx context.Context, id string, limit int32) ([]*ScanUser, error) {
	if limit > SCAN_MAX {
		limit = SCAN_MAX
	}
	if id == "" {
		id = "00000000-0000-0000-0000-000000000000"
	}
	const sql = "select id,created from user_registry where id > $1 order by id asc limit $2;"
	rows, err := es.pgSql.Query(ctx, sql, id, limit)
	if err != nil {
		return nil, es.logger.IfErrorF(err, "ScanUsers Query: %v %v", id, limit)
	}
	defer rows.Close()
	var (
		res  = make([]*ScanUser, 0)
		oops = make([]error, 0)
	)
	for rows.Next() {
		u := ScanUser{}
		if e := rows.Scan(&u.Id, &u.Created); e != nil {
			oops = append(oops, e)
		} else if u.Id != "" {
			res = append(res, &u)
		}
	}
	return res, es.logger.IfWarnF(wrapErrors(oops), "ScanUsers Scan: %v %v", id, limit)
}

func (es *entityStore) LogDeviceCleaned(ctx context.Context, id, mac string) error {
	defer panicRecover(es.logger, "LogDeviceCleaned: %v %v", mac, id)
	if id == "" {
		return nil //ignore
	}
	if mac == "" {
		mac = "000000000000"
	}
	const sql = `INSERT INTO device_clean_rm (id,mac) VALUES($1,$2) ON CONFLICT (id) DO NOTHING;`
	if _, e := es.pgSql.ExecNonQuery(ctx, sql, id, mac); e != nil {
		return es.logger.IfWarnF(e, "LogDeviceCleaned: %v %v", mac, id)
	} else {
		es.logger.Trace("LogDeviceCleaned: OK %v %v", mac, id)
	}
	return nil
}
