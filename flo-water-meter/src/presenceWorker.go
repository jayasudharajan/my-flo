package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"sort"
	"strconv"
	"sync/atomic"
	"time"
)

const ENVVAR_PRESENCE_INTERVAL_SEC = "FLO_PRESENCE_INTERVAL_SEC"
const PRESENCE_INTERVAL_SEC int = 15
const SOURCE_PRESENCE_NAME string = "presence"

// Scans for device presence at interval to refresh water usage frequently
func presenceWorker() {
	ev := getEnvOrDefault(ENVVAR_PRESENCE_INTERVAL_SEC, "")
	var intervalS int
	if n, e := strconv.Atoi(ev); e == nil {
		intervalS = n
	} else {
		intervalS = PRESENCE_INTERVAL_SEC
	}
	if intervalS <= 0 {
		logNotice("presenceWorker: DISABLED, %v=%v", ENVVAR_PRESENCE_INTERVAL_SEC, ev)
		return
	}

	interval := time.Duration(intervalS) * time.Second
	nextRun := time.Now()
	for atomic.LoadInt32(&cancel) == 0 {
		// Time to execute
		if time.Now().After(nextRun) {
			processPresentDevices()
			nextRun = time.Now().Truncate(interval).Add(interval)
		}
		// Pause the thread to release resources
		time.Sleep(time.Second)
	}
}

func processPresentDevices() {
	defer recoverPanic(_log, "processPresentDevices")
	// Get the currently present devices
	macList := getPresentDevices()
	if len(macList) == 0 {
		logDebug("processPresentDevices: Found 0 devices present")
		return
	}

	// Sort the list for predictable
	sort.Strings(macList)
	targetDate := time.Now().UTC().Truncate(time.Hour * 24)

	us := targetDate.Format("01-02T15")
	logDebug("processPresentDevices: Processing %v Devices %v", len(macList), us)
	for _, mac := range macList {
		if atomic.LoadInt32(&cancel) != 0 {
			break
		}
		if !_allow.Found(mac) {
			continue //debug reject
		}

		// Cache today's data
		atomic.AddInt64(&_qSize, 1)
		go cacheDeviceConsumption(mac, targetDate, SOURCE_PRESENCE_NAME, "processPresentDevices: today "+us)

		if canReprocessYesterday(mac) { //re-cache yesterday's data lagged
			atomic.AddInt64(&_qSize, 1)
			go cacheDeviceConsumption(mac, targetDate.Add(-24*time.Hour), SOURCE_PRESENCE_NAME, "processPresentDevices: yesterday "+us)
		}
	}
}

func presencePing() error {
	var netClient = &http.Client{
		Timeout: time.Second * 5,
	}
	url := presenceHost + "/ping"
	if req, err := http.NewRequest("GET", url, nil); err != nil {
		return logError("Presence Ping -> %v", err)
	} else if resp, err := netClient.Do(req); err != nil {
		return logError("Presence Ping -> %v", err)
	} else {
		defer resp.Body.Close()
		if resp.StatusCode >= 300 {
			return logError("Presence Ping -> status code error. %v", resp.StatusCode)
		} else {
			return nil
		}
	}
}

func getPresentDevices() []string {

	var netClient = &http.Client{
		Timeout: time.Second * 10,
	}

	url := presenceHost + "/presence/now"
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		logError("GET %v. %v", url, err.Error())
		return nil
	}

	resp, err := netClient.Do(req)

	if err != nil {
		logError("%v", err.Error())
		return nil
	}

	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		logError("GET %v status code error. %v", url, resp.StatusCode)
		return nil
	}

	jsonBytes, err := ioutil.ReadAll(resp.Body)

	data := PresencePayload{}

	err = json.Unmarshal(jsonBytes, &data)

	if err != nil {
		logError("GET %v JSON deserialization error. %v", url, err.Error())
		return nil
	}

	return data.UserPerspective.DeviceMacs
}

type PresencePayload struct {
	Date            time.Time
	UserPerspective UserPerspectivePaylod
}

type UserPerspectivePaylod struct {
	AccountIds []string
	UserIds    []string
	DeviceIds  []string
	DeviceMacs []string
}
