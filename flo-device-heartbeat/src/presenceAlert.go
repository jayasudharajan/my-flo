package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

const SHUTOFF_ONLINE_ALARM_ID = 46
const SHUTOFF_OFFLINE_ALARM_ID = 33
const SHUTOFF_STILL_OFFLINE_ALARM_ID = 50
const DETECTOR_OFFLINE_ALARM_ID = 107
const DETECTOR_ONLINE_ALARM_ID = 108
const DEVICE_MAKE_DETECTOR = "puck_oem"

const DEVICE_MAKE_SHUTOFF_V2 = "flo_device_v2"

//const DEVICE_MAKE_SHUTOFF_V1 = "flo_device_v1"

// OfflineDevice represents a record in the offline_devices table
type OfflineDevice struct {
	MacAddress             string    `db:"mac_address"`
	OfflineAt              time.Time `db:"offline_at"`
	OfflineSentAt          time.Time `db:"offline_sent_at"`
	StillOfflineLastSentAt time.Time `db:"still_offline_last_sent_at"`
	DeviceMake             string    `db:"device_make"`
}

func handlePresenceAlert(macAddress string, isOnline bool) {
	if isOnline {
		err := sendAndMarkOnline(_dbCn, _redis, OfflineDevice{MacAddress: macAddress})

		if err != nil {
			logError("handlePresenceAlert: failed to mark device online %v. %v", macAddress, err.Error())
		}
	} else {
		zeroDate := time.Time{}

		// Determine when device went offline
		lastHeardFromTime, err := getRedisLastHeardFrom(macAddress)

		if err != nil {
			logError("handlePresenceAlert: failed to retrieve state from redis for %v. %%v", macAddress, err.Error())
			lastHeardFromTime = time.Now()
		} else if lastHeardFromTime.IsZero() {
			logDebug("handlePresenceAlert: lastHeardFromTime not found in redis for %v", macAddress)
			lastHeardFromTime = time.Now()
		}

		deviceMake, err := getDeviceMake(macAddress)

		if err != nil {
			logError("handlePresenceAlert: failed to retrieve device make for %v. %v", macAddress, err.Error())
			return
		}

		// Insert into DB
		query := "INSERT INTO \"offline_devices\" (\"mac_address\", \"device_make\", \"offline_at\", \"offline_sent_at\", \"still_offline_last_sent_at\")"
		query += "VALUES ($1, $2, $3, $4, $4) "
		query += "ON CONFLICT (\"mac_address\") DO NOTHING"

		_, err = _dbCn.ExecNonQuery(query, macAddress, deviceMake, lastHeardFromTime, zeroDate)

		logDebug("handlePresenceAlert: device %v %v stored as offline at %v", macAddress, deviceMake, lastHeardFromTime)

		if err != nil {
			logError("handlePresenceAlert: failed to store offline device %v. %v", macAddress, err.Error())
		}
	}
}

type DeviceServiceData struct {
	MacAddress string `json:"macAddress"`
	Make       string `json:"make"`
}

func getDeviceMake(macAddress string) (string, error) {
	url := fmt.Sprintf("%v/devices/%v", _deviceServiceURL, macAddress)

	status, body, err := httpCall(url, "GET", nil, nil)

	if err != nil {
		return "", err
	}

	if status < 200 || status >= 300 {
		return "", fmt.Errorf("call to %v failed with status %v", url, status)
	}

	var data DeviceServiceData
	err = json.Unmarshal(body, &data)

	if err != nil {
		return "", err
	}

	return data.Make, nil
}

func alertOfflineDevices(
	db *PgSqlDb,
	redisConn *RedisConnection,
	doQuery func(db *PgSqlDb, deviceMake string) (*sql.Rows, error),
	sendAlert func(device OfflineDevice) error,
	markAlertSent func(db *PgSqlDb, device OfflineDevice) error,
	deviceMake string,
) error {

	if redisConn == nil {
		return fmt.Errorf("redis is nil")
	}

	rows, err := doQuery(db, deviceMake)
	defer rows.Close()

	if err != nil {
		return err
	}

	for rows.Next() {
		var device OfflineDevice

		err = rows.Scan(&device.MacAddress, &device.DeviceMake, &device.OfflineAt)

		if err != nil {
			logError("alertOfflineDevices:%v failed to parse offline device record", deviceMake)
			continue
		}

		// Acquire lock
		key := formatKey(device.MacAddress)
		ok, err := redisConn.SetNX(key, true, 60)

		if err != nil {
			logError("alertOfflineDevices:%v failed to SETNX %v", deviceMake, key)
			continue
		}

		if !ok {
			logDebug("alertOfflineDevices:%v failed to acquire lock for %v", deviceMake, key)
			continue
		} else {
			logDebug("alertOfflineDevices: lock acquired for %v", key)
		}

		err = sendAlert(device)

		if err != nil {
			logError("alertOfflineDevices:%v failed to send offline alert for %v. %v", deviceMake, device, err.Error())
			continue
		}

		err = markAlertSent(db, device)

		if err != nil {
			logError("alertOfflineDevices:%v failed to mark alert as sent for %v. %v", deviceMake, device, err.Error())
			continue
		}

		// Release lock
		_, err = redisConn.Delete(key)

		if err != nil {
			logDebug("alertOfflineDevices:%v failed to release lock for %v", deviceMake, key)
		}

		logDebug("alertOfflineDevices: released lock for %v", key)
	}

	return nil
}

func queryOffline(db *PgSqlDb, deviceMake string) (*sql.Rows, error) {
	if db == nil {
		return nil, fmt.Errorf("postgres is nil")
	}

	var inactiveTimePeriod time.Duration

	if strings.EqualFold(deviceMake, DEVICE_MAKE_DETECTOR) {
		inactiveTimePeriod = time.Duration(floPuckOemHeartbeatTTL)
	} else {
		inactiveTimePeriod = time.Duration(floDeviceHeartbeatTTL)
	}

	itp := time.Now().Add((-1 * inactiveTimePeriod) * time.Minute).UTC()
	zeroDate := time.Time{}
	query := `SELECT "mac_address", "device_make", "offline_at" FROM "offline_devices"
		WHERE "offline_at" <= $1
		AND "offline_sent_at" = $2
		AND "device_make" = $3`

	return db.Query(query, itp, zeroDate, deviceMake)
}

func queryStillOffline(db *PgSqlDb, deviceMake string) (*sql.Rows, error) {
	if db == nil {
		return nil, fmt.Errorf("postgres is nil")
	}

	dayAgo := time.Now().Add(-24 * time.Hour).UTC()

	zeroDate := time.Time{}
	query := `SELECT "mac_address", "device_make", "offline_at" FROM "offline_devices"
		WHERE "offline_sent_at" > $2 AND "offline_sent_at" <= $1
		AND "still_offline_last_sent_at" = $2
		AND "device_make" = $3`

	return db.Query(query, dayAgo, zeroDate, deviceMake)
}

func markOfflineSent(db *PgSqlDb, device OfflineDevice) error {
	if db == nil {
		return fmt.Errorf("postgres is nil")
	}

	now := time.Now().UTC().Format(time.RFC3339)
	query := "UPDATE \"offline_devices\" "
	query += "SET \"offline_sent_at\"=$1 "
	query += "WHERE \"mac_address\"=$2"

	logDebug("markOfflineSent: marking device %v offline alert sent at %v", device.MacAddress, now)

	_, err := db.ExecNonQuery(query, now, device.MacAddress)

	if err != nil {
		return err
	}

	logDebug("markOfflineSent: successfully marked device %v offline alert sent at %v", device.MacAddress, now)

	return nil
}

func markStillOfflineSent(db *PgSqlDb, device OfflineDevice) error {
	if db == nil {
		return fmt.Errorf("postgres is nil")
	}

	now := time.Now().UTC().Format(time.RFC3339)
	query := "UPDATE \"offline_devices\" "
	query += "SET \"still_offline_last_sent_at\"=$1 "
	query += "WHERE \"mac_address\"=$2"

	logDebug("markStillOfflineSent: marking device %v still offline alert sent at %v", device.MacAddress, now)
	_, err := db.ExecNonQuery(query, now, device.MacAddress)

	if err != nil {
		return err
	}

	logDebug("markStillOfflineSent: successfully marked device %v still offline alert sent at %v", device.MacAddress, now)

	return nil
}

func formatKey(macAddress string) string {
	return fmt.Sprintf("mutex:flo-device-heart-beat:presence:%v", macAddress)
}

func sendAndMarkOnline(db *PgSqlDb, redisConn *RedisConnection, device OfflineDevice) error {
	if db == nil {
		return fmt.Errorf("postgres is nil")
	}

	// Determine if online device was ever tracked as offline
	query := "SELECT \"device_make\", \"offline_sent_at\", \"still_offline_last_sent_at\" FROM \"offline_devices\" "
	query += "WHERE \"mac_address\"=$1"

	rows, err := db.Query(query, device.MacAddress)
	defer rows.Close()

	if rows == nil || !rows.Next() {
		return nil
	}

	err = rows.Scan(&device.DeviceMake, &device.OfflineSentAt, &device.StillOfflineLastSentAt)

	if err != nil {
		return err
	}

	// Acquire lock
	key := formatKey(device.MacAddress)
	ok, err := redisConn.SetNX(key, true, 60)

	if err != nil {
		return err
	}

	if !ok {
		return fmt.Errorf("failed to acquire lock for %v", key)
	}

	logDebug("sendAndMarkOnline: lock acquired for %v", key)

	// Send online alert
	err = sendOnlineAlert(device)

	if err != nil {
		return err
	}

	// Remove from list of offline devices
	query = "DELETE FROM \"offline_devices\" "
	query += "WHERE \"mac_address\"=$1"

	logDebug("sendAndMarkOnline: removing device %v from offline_devices", device.MacAddress)
	_, err = db.ExecNonQuery(query, device.MacAddress)

	if err != nil {
		return err
	}

	logDebug("sendAndMarkOnline: device %v successfully removed from offline_devices", device.MacAddress)

	// Release lock
	_, err = redisConn.Delete(key)

	if err != nil {
		logDebug("sendAndMarkOnline: failed to release lock for %v", key)
	}

	logDebug("sendAndMarkOnline: released lock for %v", key)

	return nil
}

func triggerAlert(macAddress string, alarmID int) error {
	url := _notificationAPIURL + "/events"
	headers := map[string]string{"Content-Type": "application/json"}
	data := map[string]interface{}{
		"macAddress": macAddress,
		"alarmId":    alarmID,
	}
	body, err := json.Marshal(data)

	if err != nil {
		return err
	}

	logDebug("triggerAlert: triggering alarm ID %v for device %v", alarmID, macAddress)
	status, _, err := httpCall(url, "POST", body, headers)

	if status < 200 || status >= 300 {
		return fmt.Errorf("failed to trigger %v alarm Id %v with status code %v", macAddress, alarmID, status)
	}

	return nil
}

func sendOfflineAlert(device OfflineDevice) error {
	var offlineAlarmID int

	if device.DeviceMake == DEVICE_MAKE_DETECTOR {
		offlineAlarmID = DETECTOR_OFFLINE_ALARM_ID
	} else {
		offlineAlarmID = SHUTOFF_OFFLINE_ALARM_ID
	}

	err := triggerAlert(device.MacAddress, offlineAlarmID)

	if err != nil {
		return err
	}

	return nil
}

func sendStillOfflineAlert(device OfflineDevice) error {
	var stillOfflineAlarmID int

	if device.DeviceMake == DEVICE_MAKE_DETECTOR {
		stillOfflineAlarmID = DETECTOR_OFFLINE_ALARM_ID
	} else {
		stillOfflineAlarmID = SHUTOFF_STILL_OFFLINE_ALARM_ID
	}

	err := triggerAlert(device.MacAddress, stillOfflineAlarmID)

	if err != nil {
		return err
	}

	return nil
}

func resolveAlert(macAddress string, alarmID int) error {
	now := time.Now().UTC()
	nowEpochMs := now.Unix() * 1000
	uuidV4, err := uuid.NewRandom()

	if err != nil {
		return err
	}
	data := map[string]interface{}{
		"id":  uuidV4,
		"ts":  nowEpochMs,
		"did": macAddress,
		"data": map[string]interface{}{
			"alarm": map[string]interface{}{
				"ht":     nowEpochMs,
				"acts":   nil,
				"reason": alarmID,
				"defer":  0,
			},
			"snapshot": map[string]interface{}{
				"tz":   "Etc/UTC",
				"lt":   now.Format("15:04:05"),
				"sm":   2,
				"f":    -1,
				"fr":   -1,
				"t":    -1,
				"p":    -1,
				"sw1":  0,
				"sw2":  0,
				"ef":   -1,
				"efd":  -1,
				"ft":   -1,
				"pmin": -1,
				"pmax": -1,
				"tmin": -1,
				"tmax": -1,
				"frl":  -1,
				"efl":  -1,
				"efdl": -1,
				"ftl":  -1,
			},
		},
		"status":         1,
		"status_message": nil,
	}
	msg, err := json.Marshal(data)

	if err != nil {
		return err
	}
	topic := "alarm-notification-status-v2"

	logDebug("sendOfflineAlert: publishing to %v message %v", topic, string(msg))

	err = kafkaConn.PublishBytes(topic, msg, nil)

	if err != nil {
		return err
	}

	return nil
}

func sendOnlineAlert(device OfflineDevice) error {
	var onlineAlarmID int
	var offlineAlarmID int
	var stillOfflineAlarmID int

	if device.DeviceMake == DEVICE_MAKE_DETECTOR {
		onlineAlarmID = DETECTOR_ONLINE_ALARM_ID
		offlineAlarmID = DETECTOR_OFFLINE_ALARM_ID
		stillOfflineAlarmID = DETECTOR_OFFLINE_ALARM_ID
	} else {
		onlineAlarmID = SHUTOFF_ONLINE_ALARM_ID
		offlineAlarmID = SHUTOFF_OFFLINE_ALARM_ID
		stillOfflineAlarmID = SHUTOFF_STILL_OFFLINE_ALARM_ID
	}

	// If offline alert sent, resolve it and send online alert
	if !device.OfflineSentAt.IsZero() {
		err := triggerAlert(device.MacAddress, onlineAlarmID)

		if err != nil {
			return err
		}

		err = resolveAlert(device.MacAddress, offlineAlarmID)

		if err != nil {
			return err
		}
	}

	// If still offline alert sent, resolve it
	if device.DeviceMake != DEVICE_MAKE_DETECTOR && !device.StillOfflineLastSentAt.IsZero() {
		err := resolveAlert(device.MacAddress, stillOfflineAlarmID)

		if err != nil {
			return err
		}
	}

	return nil
}
