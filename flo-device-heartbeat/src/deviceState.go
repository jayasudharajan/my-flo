package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"sync"
	"time"

	ot "github.com/opentracing/opentracing-go"
)

const MAX_CONCURRENT_FLUSH int = 15
const STALE_DEVICE_MINUTES float64 = 61        // Set the device as offline after 61 minutes
const STALE_DEVICE_MAX_MINUTES float64 = 10080 // Don't look at devices not heard from more than 1 week
const LAST_WRITE_SECONDS float64 = 300

var flushSemaphore chan struct{}
var lastWriteDb map[string]time.Time
var lastWriteMutex *sync.Mutex

func init() {
	flushSemaphore = make(chan struct{}, MAX_CONCURRENT_FLUSH)
	lastWriteDb = make(map[string]time.Time)
	lastWriteMutex = new(sync.Mutex)
}

type StorageConnectionStatus struct {
	Online   bool      `json:"online,omitempty"`
	Time     time.Time `json:"time,omitempty"`
	NotFound bool
	Error    error
}

type NotifyMessage struct {
	MacAddress string    `json:"macAddr"`
	Online     bool      `json:"online"`
	Verified   bool      `json:"-"`
	Time       time.Time `json:"time"`
}

const KAFKA_RE_NOTIFY_SEC = 60 * 30 //30min

// Get last time this process wrote state to this device
func timeDiffSinceLastWrite(macAddress string) time.Duration {
	lastWriteMutex.Lock()
	defer lastWriteMutex.Unlock()
	lastTime := lastWriteDb[macAddress]

	return time.Now().UTC().Sub(lastTime)
}

// trySetDeviceOnlineState writes the data to the database. if force is false, only if redis value is different
func trySetDeviceOnlineState(macAddress string, isOnline bool, force bool, ignoreSemaphore bool) bool {
	curTime := time.Now().UTC()
	if !isValidMacAddress(macAddress) {
		return false
	}

	// We want to throttle not to kill shared resources such as Redis/PG
	if !ignoreSemaphore {
		flushSemaphore <- struct{}{} // Lock
		defer func() {
			<-flushSemaphore // Release the lock
		}()
	}

	// Regardless of throttling, set the last heard from date for online device in redis
	if isOnline {
		setRedisLastHeardFrom(macAddress, curTime)
	}

	//if notify is nil, will not publish -> Kafka
	notify := &NotifyMessage{
		MacAddress: macAddress,
		Online:     isOnline,
		Time:       curTime,
	}
	// Check current state, only update on change. Skip if ignore is true.
	if !force {
		current := getStateFromRedis(macAddress)
		// If redis values exists and it matches the target state
		if !current.NotFound && current.Online == isOnline {
			// Get last time this process wrote state to this device
			deltaSeconds := timeDiffSinceLastWrite(macAddress).Seconds()
			if deltaSeconds < KAFKA_RE_NOTIFY_SEC {
				notify = nil //no need to renotify within 30min
			} else {
				notify.Verified = true
			}

			// Check if we have written to this device recently
			if deltaSeconds < LAST_WRITE_SECONDS {
				// Last time we wrote was less than min time, don't update data
				return false
			}
		} else {
			notify.Verified = true
		}
	}

	// Record locally the last time we wrote to this device
	lastWriteMutex.Lock()
	lastWriteDb[macAddress] = time.Now().UTC()
	lastWriteMutex.Unlock()

	// Write to data storage concurrently
	logDebug("trySetDeviceOnlineState: %v %v", macAddress, isOnline)
	if notify != nil {
		go publishToKafka(notify) //fire & forget, don't wait as this is not a set op
	}

	span := ot.StartSpan("trySetDeviceOnlineState:write")
	defer span.Finish()

	wg := new(sync.WaitGroup)
	wg.Add(4)

	go func(g *sync.WaitGroup, m string, o bool) {
		defer wg.Done()
		defer panicRecover("setDatabaseState(%v,%v)", m, o)
		setDatabaseState(m, o)
	}(wg, macAddress, isOnline)

	go func(g *sync.WaitGroup, m string, o bool) {
		defer wg.Done()
		defer panicRecover("setFirestoreState(%v,%v)", m, o)
		setFirestoreState(m, o)
	}(wg, macAddress, isOnline)

	go func(g *sync.WaitGroup, m string, o bool) {
		defer wg.Done()
		defer panicRecover("setRedisState(%v,%v)", m, o)
		setRedisState(m, o)
	}(wg, macAddress, isOnline)

	go func(g *sync.WaitGroup, m string, o bool) {
		defer wg.Done()
		defer panicRecover("handlePresenceAlert(%v,%v)", m, o)
		handlePresenceAlert(m, o)
	}(wg, macAddress, isOnline)

	wg.Wait()

	return true
}

func publishToKafka(lastKnown *NotifyMessage) {
	defer panicRecover("publishToKafka: %v", lastKnown)
	if !lastKnown.Verified { //if we didn't check with redis yet
		if cur := getStateFromRedis(lastKnown.MacAddress); !cur.NotFound && cur.Online == lastKnown.Online {
			if timeDiff := timeDiffSinceLastWrite(lastKnown.MacAddress).Seconds(); timeDiff < KAFKA_RE_NOTIFY_SEC {
				lastKnown = nil //no need to renotify again
			}
		}
	}
	if lastKnown != nil {
		kafkaConn.Publish(KAFKA_TOPIC_HEARTBEAT, lastKnown, []byte(lastKnown.MacAddress))
	}
}

func setFirestoreState(macAddress string, online bool) {
	instanaMethodTimer("setFirestoreState", func() {
		url := _fireWriterHost + "/v1/firestore/devices/" + macAddress
		code, _, err := httpCall(url, "POST", []byte(fmt.Sprintf("{\"isConnected\":%v}", online)), nil)

		if err != nil {
			logError("setFirestoreState: %v %v %v", macAddress, online, err.Error())
			return
		}

		if code >= 400 {
			logError("setFirestoreState: %v %v %v", macAddress, online, code)
			return
		}

		logDebug("setFirestoreState: %v %v %v", macAddress, online, code)
	})
}

func setRedisState(macAddress string, online bool) {
	instanaMethodTimer("setRedisState", func() {
		key := "device:connectivity:" + macAddress

		if online {
			_redis.Set(key, "true", 60*60)
		} else {
			_redis.Set(key, "false", 60*60)
		}

		logDebug("setRedisState: %v %v %v", macAddress, online, key)
	})
}

func setRedisLastHeardFrom(macAddress string, date time.Time) {
	instanaMethodTimer("setRedisLastHeardFrom", func() {
		key := "deviceCache:" + macAddress
		date = date.Truncate(time.Minute)

		_redis.HMSet(key, map[string]interface{}{
			"hb.lastHeardFrom": date.Format(time.RFC3339),
		}, 0)
	})
}

func getRedisLastHeardFrom(macAddress string) (lastHeardFromTime time.Time, rvErr error) {

	key := "deviceCache:" + macAddress
	result, err := _redis.HGetAll(key)

	if err != nil {
		rvErr = err
		return
	}

	ts, ok := result["hb.lastHeardFrom"]

	if !ok {
		return
	}

	lastHeardFromTime, err = time.Parse(time.RFC3339, ts)

	if err != nil {
		rvErr = err
		return
	}

	return lastHeardFromTime, rvErr
}

func setDatabaseState(macAddress string, online bool) {
	instanaMethodTimer("setDatabaseState", func() {
		var err error
		var result sql.Result

		nowUtc := time.Now().UTC()

		if online {
			result, err = _dbCn.ExecNonQuery(
				`
			INSERT INTO devices (device_id, is_connected,last_heard_from_time)
			VALUES ($1,$2,$3)
			ON CONFLICT (device_id) DO UPDATE
			SET is_connected=$2,last_heard_from_time=$3;`,
				macAddress,
				online,
				nowUtc.Truncate(time.Minute))
		} else {
			result, err = _dbCn.ExecNonQuery(
				`
			INSERT INTO devices (device_id, is_connected)
			VALUES ($1, $2)
			ON CONFLICT (device_id) DO UPDATE
			SET is_connected=$2;`,
				macAddress,
				online)
		}

		if err != nil {
			logError("setDatabaseState: %v %v %v", macAddress, online, err.Error())
		} else {
			count, _ := result.RowsAffected()
			logDebug("setDatabaseState: %v %v %v", macAddress, online, count)
		}
	})
}

func getStateFromRedis(macAddress string) StorageConnectionStatus {
	span := ot.StartSpan("getStateFromRedis")
	defer span.Finish()

	key := "device:connectivity:" + macAddress

	r, e := _redis.Get(key)

	rv := StorageConnectionStatus{}

	if e != nil {
		errStr := e.Error()

		if strings.Contains(errStr, "nil") {
			rv.NotFound = true
		} else {
			logError("getStateFromRedis: %v %v", macAddress, e.Error())
			rv.Error = e
		}

		return rv
	}

	if len(r) == 0 {
		rv.NotFound = true
	} else {
		rv.Online = strings.EqualFold(r, "true")
		rv.Error = e
	}

	return rv
}

func getStateFromDatabase(macAddress string) StorageConnectionStatus {
	span := ot.StartSpan("getStateFromDatabase")
	defer span.Finish()

	rv := StorageConnectionStatus{}

	r, err := _dbCn.QueryRow(
		"SELECT is_connected, last_heard_from_time FROM devices WHERE device_id=$1;",
		macAddress)

	if err != nil {
		logError("getStateFromDatabase: %v %v", macAddress, err.Error())
		rv.Error = err
		return rv
	}

	err = r.Scan(&rv.Online, &rv.Time)

	if err != nil {
		errStr := err.Error()
		if strings.Contains(errStr, "no rows") {
			rv.NotFound = true
		} else {
			logError("getStateFromDatabase: %v %v", macAddress, err.Error())
			rv.Error = err
		}
	}

	return rv
}

func getStaleFromDatabase() []string {
	span := ot.StartSpan("getStaleFromDatabase")
	defer span.Finish()

	now := time.Now().UTC()
	rv := make([]string, 0)

	sql := "SELECT device_id, last_heard_from_time, make FROM devices WHERE last_heard_from_time < NOW() - INTERVAL '15' MINUTE;"
	rows, err := _dbCn.Query(sql)
	if err != nil {
		logError("getStaleFromDatabase: %v", err.Error())
		return rv
	}
	defer rows.Close()

	for rows.Next() {
		macAddress := ""
		lastHeardFrom := time.Time{}
		make := ""
		rows.Scan(&macAddress, &lastHeardFrom, &make)

		var deviceStaleMinutes float64
		if strings.EqualFold(make, DEVICE_MAKE_DETECTOR) {
			deviceStaleMinutes = floPuckOemHeartbeatTTL
		} else {
			deviceStaleMinutes = floDeviceHeartbeatTTL
		}

		min := now.Sub(lastHeardFrom.UTC()).Minutes()
		if min > deviceStaleMinutes {
			if min < STALE_DEVICE_MAX_MINUTES {
				if isValidMacAddress(macAddress) {
					logTrace("EXPIRED: %v %.2f min", macAddress, min)
					rv = append(rv, strings.ToLower(macAddress))
				}
			} else {
				logTrace("SKIPPING EXPIRED: %v %.2f min, too old", macAddress, min)
			}
		}
	}

	return rv
}

func getStateFromFirestore(macAddress string) StorageConnectionStatus {
	span := ot.StartSpan("getStateFromFirestore")
	defer span.Finish()

	url := _fireWriterHost + "/v1/firestore/devices/" + macAddress

	httpClient := http.Client{
		Timeout: time.Duration(5 * time.Second),
	}

	req, reqErr := http.NewRequest("GET", url, nil)
	if reqErr != nil {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: %v %v", macAddress, reqErr)}
	}

	req.Header.Add("content-type", "application/json")
	res, errRes := httpClient.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: %s with status %d, err: %v", url, statusCode, errRes)}
	}

	if res.Body == nil {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: Body NIL %v %v", macAddress, res.StatusCode)}
	}

	defer res.Body.Close()

	if res.StatusCode >= 400 {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: %v %v", macAddress, res.StatusCode)}
	}

	byteData, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: %v %v", macAddress, err)}
	}

	if len(byteData) == 0 {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: Empty Data %v", macAddress)}
	}

	fireData := FirestoreDeviceModel{}
	err = json.Unmarshal(byteData, &fireData)

	if err != nil {
		return StorageConnectionStatus{Error: logError("getStateFromFirestore: %v %v", macAddress, err)}
	}

	rv := StorageConnectionStatus{}
	rv.Online = fireData.IsConnected

	if len(fireData.MacAddress) != 12 {
		rv.NotFound = true
	}

	return rv
}

type FirestoreDeviceModel struct {
	MacAddress  string `json:"deviceId"`
	IsConnected bool   `json:"isConnected"`
}
