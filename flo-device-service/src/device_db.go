package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/imdario/mergo"
	"github.com/labstack/gommon/log"
	"github.com/lib/pq"
	"github.com/pkg/errors"
)

const rollbackDeviceDataErrMsg = "failed to rollback %s device data, err: %v"
const conversionTimeErrMsg = "failed to convert time, err: %v"
const duplicateKeyErrorCode = "23505"

const shutoffLevelKey = "shutoffLevel"
const defaultShutoffLevel = -1

func compileUpdateQuery(table, idKey string, columnsToUpdate []string) string {
	updateTable := fmt.Sprintf("UPDATE %s", table)
	var columnsWithValues []string
	for i, f := range columnsToUpdate {
		pair := fmt.Sprintf("%s=$%d", f, i+1)
		columnsWithValues = append(columnsWithValues, pair)
	}
	setColumns := fmt.Sprintf("SET %s", strings.Join(columnsWithValues, ", "))

	return fmt.Sprintf("%s %s WHERE %s=$%d", updateTable, setColumns, idKey, len(columnsToUpdate)+1)
}

// DeviceRepository is the device repository
type PgDeviceRepository struct {
	DB *sql.DB
}

// GetDevice returns one device queried by device ID if it exists.
func (r *PgDeviceRepository) GetDevices(ctx context.Context, offset int, limit int, pairMobile *bool) (devices Devices, err error) {
	const unknownTotal = -1
	total, err := r.GetTotalRows(pairMobile)
	if err != nil {
		total = unknownTotal
	}
	meta := Meta{
		Total:  total,
		Offset: offset,
		Limit:  limit,
	}
	devices.Meta = meta

	var items []DeviceBase

	// Query column order important for the scan method. when changing the columns, ensure scan is updated
	getAllDevices := `
		SELECT
			d.device_id,
			d.fw_ver,
			d.is_connected,
			d.mobile_connectivity,
			d.fw_properties_raw,
			d.created_time,
			d.last_heard_from_time,
			d.updated_time,
			d.make,
			d.model,
			d.hw_thresholds,
			d.mute_audio_until,
		  	d.component_health,
			d.fw_properties_req,
			d.valve_state_meta,
			lfi.version,
			lfi.source_type,
			lfi.source_location
		FROM devices d
		LEFT JOIN LATERAL (
			SELECT * FROM latest_fw_info lfi
			WHERE lfi.make = d.make AND
				(lfi.device_id = d.device_id OR (lfi.device_id = '*' AND NOT EXISTS (SELECT 1 FROM latest_fw_info WHERE device_id = d.device_id)))
		) lfi ON 1 = 1`

	windowStatement := `
		OFFSET $1 LIMIT $2`

	rows, err := r.DB.QueryContext(ctx, getAllDevices+buildDeviceScanConditional(pairMobile)+windowStatement, offset, limit)
	if err != nil {
		log.Errorf("query %s has failed, err: %v", getAllDevices, err)
		return Devices{}, err
	}
	defer rows.Close()

	i := 0
	for rows.Next() {
		var device DeviceInternal
		device, _ = scanToDevice(rows.Scan, i, false)
		items = append(items, device.MapDeviceInternalToDeviceBase())
		i += 1
	}
	if err = rows.Err(); err != nil {
		return Devices{}, err
	}
	devices.Items = items
	return devices, nil
}

func (r *PgDeviceRepository) GetDevicesById(ctx context.Context, deviceIds []string) (devices Devices, err error) {
	stmt, err := r.DB.Prepare(`
		SELECT
			d.device_id,
			d.fw_ver,
			d.is_connected,
			d.mobile_connectivity,
			d.fw_properties_raw,
			d.created_time,
			d.last_heard_from_time,
			d.updated_time,
			d.make,
			d.model,
			d.hw_thresholds,
			d.mute_audio_until,
			d.component_health,
			d.fw_properties_req,
			d.valve_state_meta,
			lfi.version,
			lfi.source_type,
			lfi.source_location
		FROM devices d
		LEFT JOIN LATERAL (
			SELECT * FROM latest_fw_info lfi
			WHERE lfi.make = d.make AND
				(lfi.device_id = ANY($1) OR (lfi.device_id = '*' AND NOT EXISTS (SELECT 1 FROM latest_fw_info WHERE device_id = ANY($1))))
		) lfi ON 1 = 1
		WHERE d.device_id = ANY($1)
	`)
	if err != nil {
		log.Errorf("error preparing statement, err: %v", err)
		return Devices{}, err
	}
	defer stmt.Close()

	rows, err := stmt.QueryContext(ctx, pq.Array(deviceIds))
	if err != nil {
		log.Errorf("query has failed, err: %v", err)
		return Devices{}, err
	}
	defer rows.Close()

	var items []DeviceBase

	i := 0
	for rows.Next() {
		var device DeviceInternal
		device, _ = scanToDevice(rows.Scan, i, false)
		items = append(items, device.MapDeviceInternalToDeviceBase())
		i += 1
	}
	if err = rows.Err(); err != nil {
		return Devices{}, err
	}
	devices.Items = items
	return devices, nil
}

// GetDevice returns one device queried by device ID if it exists.
func (r *PgDeviceRepository) GetDevice(ctx context.Context, deviceId string) (device DeviceBase, err error) {

	// Query column order important for the scan method. when changing the columns, ensure scan is updated
	row := r.DB.QueryRowContext(ctx, `
		SELECT
			d.device_id,
			d.fw_ver,
			d.is_connected,
			d.mobile_connectivity,
			d.fw_properties_raw,
			d.created_time,
			d.last_heard_from_time,
			d.updated_time,
			d.make,
			d.model,
			d.hw_thresholds,
			d.mute_audio_until,
		  d.component_health,
			d.fw_properties_req,
			d.valve_state_meta,
			lfi.version,
			lfi.source_type,
			lfi.source_location
		FROM devices d
		LEFT JOIN LATERAL (
			SELECT * FROM latest_fw_info lfi
			WHERE lfi.make = d.make AND
				(lfi.device_id = $1 OR (lfi.device_id = '*' AND NOT EXISTS (SELECT 1 FROM latest_fw_info WHERE device_id = $1)))
		) lfi ON 1 = 1
		WHERE d.device_id = $1`, deviceId)

	if row == nil {
		errMsg := fmt.Sprintf("something went wrong while retrieving deviceId_%s, row is nil", deviceId)
		log.Error(errMsg)
		return DeviceBase{}, errors.New(errMsg)
	}

	deviceInternal, err := scanToDevice(row.Scan, 0, false)

	if err != nil {
		if err == sql.ErrNoRows {
			return DeviceBase{}, fmt.Errorf(NoSuchDeviceErrorMsg, deviceId)
		}
		return DeviceBase{}, err
	}

	device = deviceInternal.MapDeviceInternalToDeviceBase()

	defaultHwThresholds, err := r.RetrieveDefaultHardwareThresholds(ctx, *(device.Make), *(device.Model))
	if err != nil {
		log.Errorf("failed to retrieve default hardware thresholds for device ID %s: %v", deviceId, err)
		return device, nil
	}

	mergedHwThresholds := defaultHwThresholds
	if err := mergo.Map(&mergedHwThresholds, *device.HardwareThresholds, mergo.WithOverride, mergo.WithTransformers(FalsyValuesTransformer{})); err != nil {
		log.Errorf("failed to merge default hardware thresholds for device ID %s: %v", deviceId, err)
	}
	device.HardwareThresholds = &mergedHwThresholds
	return device, nil
}

func (r *PgDeviceRepository) SetMobileState(ctx context.Context, deviceId string, state bool) (err error) {

	_, err = r.DB.ExecContext(ctx, "UPDATE devices SET mobile_connectivity=$2, updated_time=$3 WHERE device_id=$1",
		deviceId, state, time.Now().UTC())

	return
}

func (r *PgDeviceRepository) SetLastValve(ctx context.Context, deviceId string, valveState string) (err error) {
	_, err = r.DB.ExecContext(ctx, "UPDATE devices SET valve_latest=$2, updated_time=$3 WHERE device_id=$1",
		deviceId, valveState, time.Now().UTC())

	if err != nil {
		logError("PG.SetLastValve: d: %v s: %v e: %v", deviceId, valveState, err.Error())
	}

	return err
}

func (r *PgDeviceRepository) SetLastMode(ctx context.Context, deviceId string, systemMode string) (err error) {
	_, err = r.DB.ExecContext(ctx, "UPDATE devices SET mode_latest=$2, updated_time=$3 WHERE device_id=$1",
		deviceId, systemMode, time.Now().UTC())

	if err != nil {
		logError("PG.SetLastMode: d: %v s: %v e: %v", deviceId, systemMode, err.Error())
	}

	return err
}

func (a FwUpdateReq) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *FwUpdateReq) Scan(value interface{}) error {
	if a == nil || value == nil {
		return nil
	} else if buf, ok := value.([]byte); !ok {
		return errors.New("type assertion to []byte failed")
	} else {
		return json.Unmarshal(buf, &a)
	}
}

func (v *ValveStateMeta) Value() (driver.Value, error) {
	if v == nil {
		return []byte("{}"), nil
	}
	return json.Marshal(v)
}

func (v *ValveStateMeta) Scan(value interface{}) error {
	if v == nil || value == nil {
		return nil
	} else if buf, ok := value.([]byte); !ok {
		return errors.New("type assertion to []byte failed")
	} else {
		if e := json.Unmarshal(buf, &v); e != nil {
			v.IsEmpty = true
			return e
		} else {
			if s := string(buf); s == "" || s == "{}" {
				v.IsEmpty = true
			}
			return nil
		}
	}
}

func (r *PgDeviceRepository) SetFwPropReq(ctx context.Context, rq *FwUpdateReq) error {
	if len(rq.DeviceId) < 12 {
		return logWarn("SetFwPropReq: invalid rq.DeviceId=%v", rq.DeviceId)
	}
	sql := `update devices set fw_properties_req=$1,updated_time=$2 where device_id=$3;`
	if _, e := r.DB.ExecContext(ctx, sql, rq, time.Now().UTC(), rq.DeviceId); e != nil {
		return logError("SetFwPropReq: %v | %v", rq.DeviceId, e)
	} else { //store the settings change
		go r.StoreAuditRecord(rq)
	}
	return nil
}

func (rq *FwUpdateReq) HealthTestOn() sql.NullBool {
	if rq != nil && len(rq.FwProps) != 0 {
		if v, ok := rq.FwProps["ht_times_per_day"]; ok {
			if n, e := strconv.Atoi(fmt.Sprint(v)); e == nil && n > 0 {
				return sql.NullBool{Bool: true, Valid: true}
			} else {
				return sql.NullBool{Bool: false, Valid: true}
			}
		}
	}
	return sql.NullBool{}
}

func convNilStr(s string) *string {
	if s == "" {
		return nil
	} else {
		return &s
	}
}

const (
	FWPropsAudit_Store int = iota
	FWPropsAudit_Notify
)

// white list to track changes for fw props
var FWPROPS_AUDIT_WHITELIST_HEADSUP map[string]int
var FWPROPS_AUDIT_WHITELIST_CONN map[string]int
var FWPROPS_AUDIT_WHITELIST []map[string]int

func init() {
	FWPROPS_AUDIT_WHITELIST_HEADSUP = map[string]int{
		"ht_times_per_day": FWPropsAudit_Store,
	}
	FWPROPS_AUDIT_WHITELIST_CONN = map[string]int{
		"wifi_sta_ssid": FWPropsAudit_Notify,
	}
	FWPROPS_AUDIT_WHITELIST = []map[string]int{FWPROPS_AUDIT_WHITELIST_HEADSUP, FWPROPS_AUDIT_WHITELIST_CONN}

}

func (rq *FwUpdateReq) auditWhiteListCheck(minFilter int) bool {
	if rq != nil && len(rq.FwProps) != 0 {
		for k, _ := range rq.FwProps {
			for _, wl := range FWPROPS_AUDIT_WHITELIST {
				if v, ok := wl[k]; ok && v == minFilter {
					return true
				}
			}
		}
	}
	return false
}

func (r *PgDeviceRepository) StoreAuditRecord(rq *FwUpdateReq) (lastFw *FwPropertiesRaw, e error) {
	st := time.Now()
	if rq == nil {
		return nil, errors.New("StoreAuditRecord: nil req ref")
	} else if len(rq.DeviceId) < 12 {
		return nil, errors.New("StoreAuditRecord: blank or invalid deviceId (new devices?)")
	}
	defer panicRecover("StoreAuditRecord: %v", rq.DeviceId)
	store := rq.auditWhiteListCheck(FWPropsAudit_Store)
	notify := rq.auditWhiteListCheck(FWPropsAudit_Notify)
	var (
		sql = `insert into devices_audit
		(device_id,account_id,location_id,by_user_id, fw_req,fw_req_health_test_on,fw_last_known)
		select device_id::macAddr,$2::uuid,$3::uuid,$4::uuid, $5,$6,fw_properties_raw from devices where device_id=$1
		returning fw_last_known;`
		acc  = convNilStr(rq.Meta.AccountId())
		loc  = convNilStr(rq.Meta.LocationId())
		usr  = convNilStr(rq.Meta.UserId())
		ht   = rq.HealthTestOn()
		args = []interface{}{rq.DeviceId, acc, loc, usr, rq, ht}
	)
	if !store {
		sql = `select fw_properties_raw from devices where device_id=$1`
		args = []interface{}{rq.DeviceId}
	}

	lastFw = &FwPropertiesRaw{}
	row := r.DB.QueryRow(sql, args...)
	stmtError := row.Scan(lastFw)

	if stmtError != nil {
		if store && stmtError.Error() == "sql: no rows in result set" { //must be initial insert or device not found
			stmtError = errors.Wrapf(stmtError, "StoreAuditRecord: device not found or initial insert for dev=%v | %v", rq.DeviceId, args)
			logNotice(stmtError.Error())
			return nil, stmtError
		}
		return nil, logError("StoreAuditRecord: %v | %v", args, stmtError)
	}

	logDebug("StoreAuditRecord: OK %vms | dev=%v acc=%v loc=%v usr=%v ht=%v",
		time.Since(st).Milliseconds(), rq.DeviceId, acc, loc, usr, ht)

	if notify {
		ae := AuditStoredEvent{
			MacAddr:       rq.DeviceId,
			ChangeRequest: rq,
			PrevFwInfo:    lastFw,
		}
		go r.notifyAuditCallbacks(&ae)
	}
	return lastFw, nil
}

type AuditStoredEvent struct {
	MacAddr       string           `json:"macAddress,omitempty"`
	ChangeRequest *FwUpdateReq     `json:"changeRequest,omitempty"`
	PrevFwInfo    *FwPropertiesRaw `json:"prevDeviceInfo,omitempty"`
}
type AuditStoredCallback func(*AuditStoredEvent)

var AUDIT_CALLBACKS = make(map[*AuditStoredCallback]bool) //singleton-ish to ensure no duplicate function pointer registration
var _auditCbLock = sync.RWMutex{}

func (r *PgDeviceRepository) RegisterAuditStoreEvents(cb AuditStoredCallback) bool {
	if cb != nil {
		_auditCbLock.Lock()
		defer _auditCbLock.Unlock()
		if _, ok := AUDIT_CALLBACKS[&cb]; !ok {
			AUDIT_CALLBACKS[&cb] = true
			return true
		}
	}
	return false
}

func (r *PgDeviceRepository) notifyAuditCallbacks(ae *AuditStoredEvent) {
	if ae != nil {
		_auditCbLock.RLock()
		defer _auditCbLock.RUnlock()
		defer panicRecover("notifyAuditCallbacks: %v", ae.MacAddr)
		for cbFunc, _ := range AUDIT_CALLBACKS {
			if cbFunc != nil {
				(*cbFunc)(ae)
			}
		}
	}
}

func (a FwPropertiesRaw) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *FwPropertiesRaw) Scan(value interface{}) error {
	if a == nil || value == nil {
		return nil
	} else if buf, ok := value.([]byte); !ok {
		return errors.New("type assertion to []byte failed")
	} else {
		return json.Unmarshal(buf, &a)
	}
}

// UpsertDevice inserts or updates device properties data into the device table.
func (r *PgDeviceRepository) UpsertDevice(ctx context.Context, device DeviceInternal) (err error) {
	// TODO: differentiate times between updated and last_heard_from when the POST to device props is implemented
	t := time.Now().UTC().Format(time.RFC3339)

	row := r.DB.QueryRowContext(ctx, `
		SELECT
			d.device_id,
			d.fw_ver,
			d.is_connected,
			d.mobile_connectivity,
			d.fw_properties_raw,
			d.created_time,
			d.last_heard_from_time,
			d.updated_time,
			d.make,
			d.model,
			d.hw_thresholds,
			d.mute_audio_until,
		  	d.component_health,
			d.fw_properties_req,
			d.valve_state_meta,
			lfi.version,
			lfi.source_type,
			lfi.source_location
		FROM devices d
		LEFT JOIN LATERAL (
			SELECT * FROM latest_fw_info lfi
			WHERE lfi.make = d.make AND
				(lfi.device_id = $1 OR (lfi.device_id = '*' AND NOT EXISTS (SELECT 1 FROM latest_fw_info WHERE device_id = $1)))
		) lfi ON 1 = 1
		WHERE d.device_id = $1`, device.DeviceId)

	storedOrNewDevice, err := scanToDevice(row.Scan, 0, true)
	if err != nil {
		return err
	}

	// Hand merge the properties
	if device.ComponentHealth != nil {
		// Existing component is nil, create a record
		if storedOrNewDevice.ComponentHealth == nil {
			storedOrNewDevice.ComponentHealth = new(ComponentHealth)
		}

		if device.ComponentHealth.Water != nil {
			if storedOrNewDevice.ComponentHealth.Water == nil {
				storedOrNewDevice.ComponentHealth.Water = new(ComponentInfo)
			}
			if isValidComponentHealth(device.ComponentHealth.Water.Health) &&
				!strings.EqualFold(storedOrNewDevice.ComponentHealth.Water.Health, device.ComponentHealth.Water.Health) {
				storedOrNewDevice.ComponentHealth.Water.Health = device.ComponentHealth.Water.Health
				storedOrNewDevice.ComponentHealth.Water.Updated = time.Now().UTC()
			}
		}

		if device.ComponentHealth.PSI != nil {
			if storedOrNewDevice.ComponentHealth.PSI == nil {
				storedOrNewDevice.ComponentHealth.PSI = new(ComponentInfo)
			}
			if isValidComponentHealth(device.ComponentHealth.PSI.Health) &&
				!strings.EqualFold(storedOrNewDevice.ComponentHealth.PSI.Health, device.ComponentHealth.PSI.Health) {
				storedOrNewDevice.ComponentHealth.PSI.Health = device.ComponentHealth.PSI.Health
				storedOrNewDevice.ComponentHealth.PSI.Updated = time.Now().UTC()
			}
		}

		if device.ComponentHealth.Temp != nil {
			if storedOrNewDevice.ComponentHealth.Temp == nil {
				storedOrNewDevice.ComponentHealth.Temp = new(ComponentInfo)
			}
			if isValidComponentHealth(device.ComponentHealth.Temp.Health) &&
				!strings.EqualFold(storedOrNewDevice.ComponentHealth.Temp.Health, device.ComponentHealth.Temp.Health) {
				storedOrNewDevice.ComponentHealth.Temp.Health = device.ComponentHealth.Temp.Health
				storedOrNewDevice.ComponentHealth.Temp.Updated = time.Now().UTC()
			}
		}

		if device.ComponentHealth.Valve != nil {
			if storedOrNewDevice.ComponentHealth.Valve == nil {
				storedOrNewDevice.ComponentHealth.Valve = new(ComponentInfo)
			}
			if isValidComponentHealth(device.ComponentHealth.Valve.Health) &&
				!strings.EqualFold(storedOrNewDevice.ComponentHealth.Valve.Health, device.ComponentHealth.Valve.Health) {
				storedOrNewDevice.ComponentHealth.Valve.Health = device.ComponentHealth.Valve.Health
				storedOrNewDevice.ComponentHealth.Valve.Updated = time.Now().UTC()
			}
		}

		if device.ComponentHealth.RH != nil {
			if storedOrNewDevice.ComponentHealth.RH == nil {
				storedOrNewDevice.ComponentHealth.RH = new(ComponentInfo)
			}
			if isValidComponentHealth(device.ComponentHealth.RH.Health) &&
				!strings.EqualFold(storedOrNewDevice.ComponentHealth.RH.Health, device.ComponentHealth.RH.Health) {
				storedOrNewDevice.ComponentHealth.RH.Health = device.ComponentHealth.RH.Health
				storedOrNewDevice.ComponentHealth.RH.Updated = time.Now().UTC()
			}
		}
	}

	componentHealthJson := "{}"
	if storedOrNewDevice.ComponentHealth != nil {
		jsonB, e := json.Marshal(storedOrNewDevice.ComponentHealth)
		if e != nil {
			logError("unable to serialize componentHealth to db. %v %v", device.DeviceId, e.Error())
			componentHealthJson = "{}"
		} else {
			componentHealthJson = string(jsonB)
		}
	}

	if device.FwPropertiesRaw == nil {
		device.FwUpdateReq = nil
	} else if device.FwPropertiesRaw.Properties != nil && len(*device.FwPropertiesRaw.Properties) != 0 {
		if device.FwUpdateReq == nil {
			device.FwUpdateReq = &FwUpdateReq{}
		}
		device.FwUpdateReq.FwProps = make(map[string]interface{}) //nuke & clone
		if device.FwPropertiesRaw.DeviceId != nil {
			device.FwUpdateReq.DeviceId = *device.FwPropertiesRaw.DeviceId
		}
		if jm, e := json.Marshal(*device.FwPropertiesRaw.Properties); e == nil {

			if e := json.Unmarshal(jm, &device.FwUpdateReq.FwProps); e != nil {
				log.Warnf("UpsertDevice: unable to clone storedOrNewDevice.FwPropertiesRaw, using shallow copy")
				for k, v := range *device.FwPropertiesRaw.Properties {
					device.FwUpdateReq.FwProps[k] = v
				}
			}
		}
	}

	mergedFwProperties := storedOrNewDevice.FwPropertiesRaw
	if device.FwPropertiesRaw != nil {
		if err := mergo.Merge(mergedFwProperties, *(device.FwPropertiesRaw), mergo.WithOverride, mergo.WithTransformers(FalsyValuesTransformer{})); err != nil {
			log.Errorf("UpsertDevice: failed to merge firmware properties for device id %s: %v", device.DeviceId, err)
		}
	}

	fwPropertiesRawBytes, err := json.Marshal(mergedFwProperties)
	if err != nil {
		logError("UpsertDevice: failed to marshal FwPropertiesRaw for deviceId_%v, err: %v", *device.DeviceId, err)
		return err
	}

	mergedHwThresholds := storedOrNewDevice.HardwareThresholds
	if device.HardwareThresholds != nil {
		if err := mergo.Merge(mergedHwThresholds, *(device.HardwareThresholds), mergo.WithOverride, mergo.WithTransformers(FalsyValuesTransformer{})); err != nil {
			log.Errorf("UpsertDevice: failed to merge hardware thresholds for device id %v: %v", *device.DeviceId, err)
		}
	}

	hwThresholdsBytes, err := json.Marshal(mergedHwThresholds)
	if err != nil {
		logError("UpsertDevice: failed to marshal HardwareThreholds for deviceId_%v, err: %v", *device.DeviceId, err)
		return err
	}

	// Fix the DB version
	if device.FwVersion == nil || len(*(device.FwVersion)) == 0 || *(device.FwVersion) == undefined {
		if storedOrNewDevice.FwVersion != nil {
			device.FwVersion = storedOrNewDevice.FwVersion
		} else {
			v := "0.0.0"
			device.FwVersion = &v
		}
	}

	if device.Make == nil {
		device.Make = storedOrNewDevice.Make
	}

	if device.Model == nil {
		device.Model = storedOrNewDevice.Model
	}

	if device.MuteAudioUntil == nil {
		device.MuteAudioUntil = storedOrNewDevice.MuteAudioUntil
	}

	device.IsConnected = storedOrNewDevice.IsConnected

	healthTestOn := device.FwPropertiesRaw.HealthTestOn()
	if healthTestOn == nil {
		healthTestOn = storedOrNewDevice.FwPropertiesRaw.HealthTestOn()
	}

	if device.ValveStateMeta == nil {
		var (
			og = Str(storedOrNewDevice.ValveState) //original valve state
			nu = Str(device.ValveState)            //new valve state
		)
		if (og == "" || !isValveOpenCloseCmd(og)) && storedOrNewDevice.ValveStateMeta != nil {
			og = storedOrNewDevice.ValveStateMeta.Target
		}
		if isValveOpenCloseCmd(nu) && !strings.EqualFold(nu, og) {
			logDebug("UpsertDevice: %v diff set BLANK | new=%v og=%v", Str(device.DeviceId), nu, og)
			device.ValveStateMeta = &ValveStateMeta{}
		} else if storedOrNewDevice.ValveStateMeta != nil { //copy if not given
			logDebug("UpsertDevice: %v COPY meta | new=%v og=%v | %v", Str(device.DeviceId), nu, og, toJson(storedOrNewDevice.ValveStateMeta))
			device.ValveStateMeta = storedOrNewDevice.ValveStateMeta
		} else {
			logDebug("UpsertDevice: %v not given, left NULL | new=%v og=%v", Str(device.DeviceId), nu, og)
		}
	} else {
		logDebug("UpsertDevice: %v meta is PROVIDED | %v", Str(device.DeviceId), toJson(device.ValveStateMeta))
	}

	_, err = r.DB.ExecContext(ctx, `
		INSERT INTO devices (
			device_id,
			fw_ver,
			is_connected,
			fw_properties_raw,
    		updated_time,
			last_heard_from_time,
			make,
			model,
			hw_thresholds,
			mute_audio_until,
			component_health,
			fw_properties_req,
			fw_health_test_on,
			valve_state_meta
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		ON CONFLICT (device_id)
			DO UPDATE SET (
				fw_ver,
				fw_properties_raw,
        		updated_time,
				make,
				model,
				hw_thresholds,
				mute_audio_until,
				component_health,
				fw_properties_req,
				fw_health_test_on, 
				valve_state_meta
			) = ($2, $4, $5, $7, $8, $9, $10, $11, $12, $13, $14)
		WHERE devices.device_id = $1`,
		*(device.DeviceId),
		*(device.FwVersion),
		*(device.IsConnected),
		fwPropertiesRawBytes,
		t,
		t,
		*(device.Make),
		*(device.Model),
		hwThresholdsBytes,
		*(device.MuteAudioUntil),
		componentHealthJson,
		device.FwUpdateReq,
		healthTestOn,
		device.ValveStateMeta,
	)
	if err != nil {
		return err
	} else {
		go func(fw *FwUpdateReq) {
			r.StoreAuditRecord(fw)
		}(device.FwUpdateReq)
		return nil
	}
}

func isValveOpenCloseCmd(s string) bool {
	switch strings.ToLower(s) {
	case VALVE_STATE_OPEN, VALVE_STATE_CLOSED:
		return true
	default:
		return false
	}
}

func (fr *FwPropertiesRaw) HealthTestOn() *bool {
	if fr != nil && fr.Properties != nil {
		fw := *fr.Properties
		if v, ok := fw["ht_times_per_day"]; ok {
			ht := false
			if n, e := strconv.Atoi(fmt.Sprint(v)); e == nil && n > 0 {
				ht = true
			}
			return &ht
		}
	}
	return nil
}

func isValidComponentHealth(v string) bool {
	switch v {
	case "ok":
		return true
	case "broken":
		return true
	case "warning":
		return true
	default:
		return false
	}
}

// ArchiveDevice deletes device properties data into from device table and makes a copy into another table
func (r *PgDeviceRepository) ArchiveDevice(deviceId, icdId, locationId string) (err error) {
	err = tx(r.DB, func(tx *sql.Tx) error {
		// snapshot of the deleted device data
		res, err := tx.Exec(`INSERT into deleted_devices
			SELECT $1 as id, $2 as location_id, device_id, to_json(d) as device_data_raw
			FROM devices d
			WHERE d.device_id = $3`, icdId, locationId, deviceId)
		if err == nil {
			if count, _ := res.RowsAffected(); count < 1 {
				return fmt.Errorf(NoSuchDeviceErrorMsg, deviceId)
			}
		} else {
			log.Errorf("failed to snapshot %s device data, err: %v", deviceId, err)
			return err
		}

		// delete the device from the main source
		res, err = tx.Exec("DELETE FROM devices WHERE device_id=$1", deviceId)
		if err != nil {
			log.Errorf("failed to delete %s device data, err: %v", deviceId, err)
			return err
		}
		if count, _ := res.RowsAffected(); count == 0 {
			return fmt.Errorf(NoSuchDeviceErrorMsg, deviceId)
		}
		return nil
	})
	return
}

// DeleteDevice deletes device properties data from device table.
func (r *PgDeviceRepository) DeleteDevice(deviceId string) (err error) {
	res, err := r.DB.Exec("DELETE FROM devices WHERE device_id=$1", deviceId)
	if err != nil {
		log.Errorf("failed to delete %s device data, err: %v", deviceId, err)
	}
	count, _ := res.RowsAffected()
	// if no rows has been deleted
	if count == 0 {
		return fmt.Errorf(NoSuchDeviceErrorMsg, deviceId)
	}
	return nil
}

// GetTotalRows gets total rows
func (r *PgDeviceRepository) GetTotalRows(ltePaired *bool) (int, error) {
	var count int
	statementName := "total rows count statement"
	stmt, err := r.DB.Prepare("SELECT COUNT(*) as count FROM devices d" + buildDeviceScanConditional(ltePaired))
	if err != nil {
		log.Errorf("failed to prepare %s, err: %v", statementName, err)
		return 0, err
	}
	err = stmt.QueryRow().Scan(&count)
	if err != nil {
		log.Errorf("failed to get/scan total rows into count var, err: %v", err)
		return 0, err
	}
	err = stmt.Close()
	if err != nil {
		log.Errorf("failed to close %s, err: %v", statementName, err)
		// swallow an error if we get the count
		if count == 0 {
			return 0, err
		}
	}
	return count, nil
}

func buildDeviceScanConditional(pairMobile *bool) (conditional string) {
	conditional = EmptyString
	if pairMobile != nil {
		conditional = fmt.Sprintf(" WHERE d.mobile_connectivity = %v", *pairMobile)
	}
	return
}

func (r *PgDeviceRepository) RetrieveDefaultFirmwareValues(deviceMake string, deviceModel string) ([]*DefaultFirmwareProperty, error) {
	properties := make([]*DefaultFirmwareProperty, 0)
	// 20 is the length of 'firmwareProperties.' + 1
	rows, err := r.DB.Query(`SELECT SUBSTRING(key, 20), value, provisioning FROM global_device_config WHERE make = $1 AND model = $2 AND key LIKE 'firmwareProperties.%'`, deviceMake, deviceModel)
	if err != nil {
		return properties, err
	}
	defer rows.Close()

	var key, valueStr, provisioningStr string
	for rows.Next() {
		rows.Scan(&key, &valueStr, &provisioningStr)
		var provisioning FirmwarePropertyProvisioning
		if err := json.Unmarshal([]byte(provisioningStr), &provisioning); err != nil {
			return properties, err
		}
		var value interface{} = valueStr
		if valueInt, err := strconv.Atoi(valueStr); err == nil {
			value = valueInt
		}
		properties = append(properties, &DefaultFirmwareProperty{
			Key:          key,
			Value:        value,
			Provisioning: &provisioning,
		})
	}
	if err = rows.Err(); err != nil {
		return properties, err
	}

	return properties, nil
}

func (r *PgDeviceRepository) RetrieveDefaultHardwareThresholds(ctx context.Context, deviceMake string, deviceModel string) (HardwareThresholds, error) {
	thresholdMap := make(map[string]interface{})
	defaultHwThresholds := HardwareThresholds{}
	// 20 is the length of 'hardwareThresholds.' + 1
	rows, err := r.DB.QueryContext(ctx, `SELECT SUBSTRING(key, 20), value FROM global_device_config WHERE make = $1 AND model = $2 AND key LIKE 'hardwareThresholds.%'`, deviceMake, deviceModel)
	if err != nil {
		return defaultHwThresholds, err
	}
	defer rows.Close()

	var key string
	var value string
	for rows.Next() {
		rows.Scan(&key, &value)
		thresholdKeysToMap(strings.Split(key, "."), value, thresholdMap)
	}
	if err = rows.Err(); err != nil {
		return defaultHwThresholds, err
	}
	defaultHwThresholdsJson, err := json.Marshal(thresholdMap)
	if err != nil {
		return defaultHwThresholds, err
	}
	if err := json.Unmarshal(defaultHwThresholdsJson, &defaultHwThresholds); err != nil {
		return defaultHwThresholds, err
	}
	return defaultHwThresholds, nil
}

func thresholdKeysToMap(keys []string, value string, root map[string]interface{}) {
	head := keys[0]
	if len(keys) == 1 {
		floatValue, err := strconv.ParseFloat(value, 64)
		if err == nil {
			root[head] = floatValue
		} else {
			boolValue, err := strconv.ParseBool(value)
			if err == nil {
				root[head] = boolValue
			} else {
				root[head] = value
			}
		}
	} else {
		_, found := root[head]
		if !found {
			root[head] = make(map[string]interface{})
		}
		thresholdKeysToMap(keys[1:], value, root[head].(map[string]interface{}))
	}
}

type scanFunc func(...interface{}) error

func scanToDevice(scan scanFunc, rowNum int, useDefaults bool) (DeviceInternal, error) {

	var deviceInternal DeviceInternal
	var firmwareVersion sql.NullString
	var isConnected sql.NullBool
	var fwPropertiesRaw FwPropertiesRaw
	var created sql.NullString
	var lastHeard sql.NullString
	var updated sql.NullString
	var deviceMake sql.NullString
	var deviceModel sql.NullString
	var hwThresholds HardwareThresholds
	var muteAudioUntil time.Time
	var version sql.NullString
	var sourceType sql.NullString
	var sourceLocation sql.NullString
	var componentHealthJson sql.NullString
	var mobile sql.NullBool

	var fwPropertiesRawBytes []byte
	var hwThresholdsBytes []byte
	var valveStateMeta ValveStateMeta
	fwUpdateReqJSON := FwUpdateReq{}

	err := scan(
		&deviceInternal.DeviceId,
		&firmwareVersion,
		&isConnected,
		&mobile,
		&fwPropertiesRawBytes,
		&created,
		&lastHeard,
		&updated,
		&deviceMake,
		&deviceModel,
		&hwThresholdsBytes,
		&muteAudioUntil,
		&componentHealthJson,
		&fwUpdateReqJSON,
		&valveStateMeta,
		&version,
		&sourceType,
		&sourceLocation,
	)
	if err != nil {
		if err == sql.ErrNoRows && useDefaults {
			now := time.Now().UTC().Format(time.RFC3339)
			firmwareVersion = sql.NullString{String: "0.0.0", Valid: true}
			isConnected = sql.NullBool{Bool: false, Valid: true}
			deviceMake = sql.NullString{String: "flo_device_v2", Valid: true}
			deviceModel = sql.NullString{String: "flo_device_075_v2", Valid: true}
			created = sql.NullString{String: now, Valid: true}
			lastHeard = sql.NullString{String: now, Valid: true}
			updated = sql.NullString{String: now, Valid: true}
			muteAudioUntil = time.Unix(0, 0)
		} else {
			return DeviceInternal{}, err
		}
	}

	deviceInternal.FwUpdateReq = &fwUpdateReqJSON
	if valveStateMeta.IsEmpty {
		deviceInternal.ValveStateMeta = nil
	} else {
		deviceInternal.ValveStateMeta = &valveStateMeta
	}
	deviceInternal.FwVersion = &firmwareVersion.String
	deviceInternal.IsConnected = &isConnected.Bool
	deviceInternal.IsMobile = &mobile.Bool
	deviceInternal.Make = &deviceMake.String
	deviceInternal.Model = &deviceModel.String
	deviceInternal.MuteAudioUntil = &muteAudioUntil

	if componentHealthJson.Valid && len(componentHealthJson.String) > 2 {
		tmp := ComponentHealth{}
		e := json.Unmarshal([]byte(componentHealthJson.String), &tmp)
		if e == nil {
			deviceInternal.ComponentHealth = &tmp
		}
	}

	if version.Valid {
		deviceInternal.LatestFwInfo = &FirmwareInfo{
			Version:        &version.String,
			SourceType:     &sourceType.String,
			SourceLocation: &sourceLocation.String,
		}
	}

	if len(hwThresholdsBytes) > 0 {
		err = json.Unmarshal(hwThresholdsBytes, &hwThresholds)
		if err != nil {
			log.Errorf("failed to unmarshal hardware thresholds for device id %s, err: %v", deviceInternal.DeviceId, err)
			deviceInternal.HardwareThresholds = &HardwareThresholds{}
		} else {
			deviceInternal.HardwareThresholds = &hwThresholds
		}
	} else {
		deviceInternal.HardwareThresholds = &HardwareThresholds{}
	}

	if len(fwPropertiesRawBytes) != 0 {
		err = json.Unmarshal(fwPropertiesRawBytes, &fwPropertiesRaw)
		if err != nil {
			log.Errorf("failed to unmarshal fwPropertiesRawBytes to fwPropertiesRaw struct for deviceId_%s, err: %v", deviceInternal.DeviceId, err)
			deviceInternal.FwPropertiesRaw = &FwPropertiesRaw{}
		} else {
			deviceInternal.FwPropertiesRaw = &fwPropertiesRaw
		}
	} else {
		deviceInternal.FwPropertiesRaw = &FwPropertiesRaw{}
	}

	tc, err := time.Parse(time.RFC3339, created.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	deviceInternal.Created = &tc

	tlh, err := time.Parse(time.RFC3339, lastHeard.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	deviceInternal.LastHeardFrom = &tlh

	tu, err := time.Parse(time.RFC3339, updated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	deviceInternal.Updated = &tu

	return deviceInternal, nil
}

// Mergo Merge will not merge falsy values.
// https://github.com/imdario/mergo/issues/89
type FalsyValuesTransformer struct {
}

func (t FalsyValuesTransformer) Transformer(typ reflect.Type) func(dst, src reflect.Value) error {
	if typ == reflect.TypeOf(bool(false)) || typ == reflect.TypeOf(float64(0.0)) {
		return func(dst, src reflect.Value) error {
			if dst.CanSet() {
				dst.Set(src)
			}
			return nil
		}
	}
	return nil
}

const SQL_TAIL_DEV = "select device_id,is_connected,fw_properties_raw->'properties'->>'device_installed' as installed,make,model from devices where device_id > $1 order by device_id asc limit $2;"

func (d *PgDeviceRepository) TailDeviceSummary(ctx context.Context, req *TailDeviceReq) (*TailDeviceResp, error) {
	if req.Limit < 1 {
		req.Normalize()
	}
	var (
		res = &TailDeviceResp{Params: *req, Devices: make([]*DeviceSummary, 0)}
		es  = make([]error, 0)
		c   = 0
	)
	if rows, e := d.DB.QueryContext(ctx, SQL_TAIL_DEV, req.DeviceId, req.Limit); e != nil {
		log.Errorf("TailDeviceSummary: failed to query '%v' params %v, err: %v", SQL_TAIL_DEV, req, e)
		return nil, e
	} else {
		defer rows.Close()
		for rows.Next() {
			item := DeviceSummary{}
			var installed sql.NullString
			if e = rows.Scan(&item.DeviceId, &item.IsConnected, &installed, &item.Make, &item.Model); e != nil {
				es = append(es, e)
			} else {
				item.IsInstalled = installed.Valid && strings.EqualFold(installed.String, "true")
				res.Devices = append(res.Devices, &item)
			}
			c++
		}
		res.LastRowFetched = c < req.Limit
		return res, wrapErrors(es)
	}
}

func tx(db *sql.DB, txFunc func(*sql.Tx) error) (err error) {
	tx, err := txBegin(db)
	if err != nil {
		return
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			txHandleError(tx.Rollback())
		} else {
			err = tx.Commit()
			txHandleError(err)
		}
	}()
	err = txFunc(tx)
	return err
}

func txHandleError(err error) {
	if err != nil {
		log.Errorf("failed devices transaction. err: %v", err)
	}
}
func txBegin(db *sql.DB) (*sql.Tx, error) {
	t, e := db.Begin()
	txHandleError(e)
	return t, e
}
