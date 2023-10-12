package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

const KAFKA_TOPIC_TELEMETRY string = "telemetry-v3"
const KAFKA_TOPIC_VALVE_STATE string = "valve-state-v1"
const KAFKA_TOPIC_SYSTEM_MODE string = "system-mode-v1"
const KAFKA_TOPIC_DIRECTIVERESPONSE string = "directives-response-v2"
const KAFKA_TOPIC_CONNECTIVITY string = "device-connectivity-status-v2"
const KAFKA_TOPIC_HEARTBEAT string = "device-heartbeat-status"
const KAFKA_TOPIC_TELEMETRY_PUCK string = "telemetry-puck-v1"
const KAFKA_TOPIC_ENTITY_ACTIVITY string = "entity-activity-v1"
const KAFKA_TOPIC_NOTIFICATIONS string = "notifications-v2"
const KAFKA_TOPIC_BULK_FILE string = "bulk-telemetry-files"
const KAFKA_TOPIC_DEV_PROPS string = "device-properties-pub-v1"
const STALE_DEVICE_MUTEX_KEY string = "mutex:heartbeat:staleDeviceProcess"
const STALE_DEVICE_MUTEX_SECONDS int = 300

var kafkaMessageCount int64
var kafkaConn *KafkaConnection
var stateChannel chan DeviceEvent
var _flushDuration time.Duration
var _infoDuration time.Duration
var _forceInterval time.Duration
var _notificationAlarmIdAllowed map[int]string
var _propReasonWhitelist map[string]bool

func init() {
	_flushDuration = time.Duration(10 * time.Second)
	_infoDuration = time.Minute
	_forceInterval = time.Duration(time.Minute * 30)

	// TODO: This needs to be data driven, such as: retrieve all alarms from NR API, use alarms with tag of 'heartbeat'
	_notificationAlarmIdAllowed = map[int]string{
		10:  "Fast Water Flow",
		11:  "High Water Usage",
		15:  "Low PSI",
		16:  "High PSI",
		26:  "Extended Water Use",
		70:  "Unusual flow rate",
		71:  "Unusual duration",
		72:  "Unusual activity at this time of day",
		73:  "Unusual activity",
		74:  "Unusual volume",
		100: "Puck: Water Detected",
	}

	_propReasonWhitelist = map[string]bool{
		"set":       true,
		"heartbeat": true,
		"directive": true,
	}
}

type DeviceEvent struct {
	MacAddress string    `json:"macAddress,omitempty"`
	Online     bool      `json:"online,omitempty"`
	Time       time.Time `json:"time,omitempty"`
}

func startHeartBeat() {

	kafka, _ := OpenKafka(kafkaHost, nil)
	topics := []string{
		KAFKA_TOPIC_TELEMETRY,
		KAFKA_TOPIC_VALVE_STATE,
		KAFKA_TOPIC_SYSTEM_MODE,
		KAFKA_TOPIC_DIRECTIVERESPONSE,
		KAFKA_TOPIC_CONNECTIVITY,
		KAFKA_TOPIC_TELEMETRY_PUCK,
		KAFKA_TOPIC_BULK_FILE,
		KAFKA_TOPIC_NOTIFICATIONS,
		KAFKA_TOPIC_DEV_PROPS,
	}
	_ = topics
	if kafka == nil {
		logError("heartBeatWorker: Can't continue, exiting")
		os.Exit(20)
	}

	_, err := kafka.Subscribe(kafkaGroupId, topics, processKafkaMessage)
	if err != nil {
		logError("heartBeatWorker: Can't subscribe to topics, exiting. %v", topics)
		os.Exit(20)
	}

	_, err = kafka.Subscribe(kafkaGroupId, []string{KAFKA_TOPIC_ENTITY_ACTIVITY}, processEntityActivity)
	if err != nil {
		logError("heartBeatWorker: Can't subscribe to topics, exiting. %v", KAFKA_TOPIC_ENTITY_ACTIVITY)
		os.Exit(20)
	}

	kafkaConn = kafka
	stateChannel = make(chan DeviceEvent, 1)
	go heartBeatDataWorker()
}

func processEntityActivity(item *kafka.Message) {
	if item == nil {
		return
	}
	if len(item.Value) == 0 {
		return
	}
	if item.TopicPartition.Topic == nil {
		return
	}

	act := new(EntityActivityTopicModel)
	err := json.Unmarshal(item.Value, &act)
	if err != nil {
		logWarn("processEntityActivity: %v", err.Error())
		return
	}

	// We are only looking for device -> deleted events
	if !strings.EqualFold(act.Type, "device") || !strings.EqualFold(act.Action, "deleted") {
		return
	}

	// No object
	if len(act.Item) == 0 {
		logWarn("processEntityActivity: item property is missing")
		return
	}

	mac := act.Item["macAddress"]
	if mac == nil {
		logWarn("processEntityActivity: item missing macAddress property")
		return
	}

	macAddress := fmt.Sprintf("%v", mac)
	if !isValidMacAddress(macAddress) {
		logWarn("processEntityActivity: invalid mac address: %v", macAddress)
	}

	trySetDeviceOnlineState(macAddress, false, true, true)

	logDebug("processEntityActivity: device %v deleted, set to false", macAddress)
}

type EntityActivityTopicModel struct {
	Id     string                 `json:"id"`
	Date   time.Time              `json:"date"`
	Type   string                 `json:"type"`
	Action string                 `json:"action"`
	Item   map[string]interface{} `json:"item"`
}

func processKafkaMessage(item *kafka.Message) {
	if item == nil {
		return
	}
	if len(item.Value) == 0 {
		return
	}
	if item.TopicPartition.Topic == nil {
		return
	}
	pname := *item.TopicPartition.Topic
	device := parseDevice(pname, item.Value)

	// Device is marked online, but we are missing id
	if device.Online && len(device.MacAddress) != 12 {
		logWarn("processKafkaMessage: missing device id %v", pname)
		return
	}

	if !validDate(device.Time) {
		logDebug("processKafkaMessage: expired message %v %v %v",
			device.MacAddress, pname, device.Time.Format(time.RFC3339))
		return
	}

	stateChannel <- device
}

func heartBeatDataWorker() {
	infoTimer := time.NewTicker(_infoDuration)
	flushTimer := time.NewTicker(_flushDuration)
	staleTimer := time.NewTicker(time.Minute)
	dbOnline := make(map[string]bool)
	dbOffline := make(map[string]bool)
	var totalUpdateCount int64 = 0

	for {
		select {
		case msg := <-stateChannel:
			if len(msg.MacAddress) == 12 && validDate(msg.Time) {
				if msg.Online {
					dbOnline[msg.MacAddress] = true
				} else {
					dbOffline[msg.MacAddress] = true
					delete(dbOnline, msg.MacAddress)
				}
			}

		case <-infoTimer.C:
			logInfo("heartBeatDataWorker: Kafka Messages Consumed: %v, Records Updated: %v",
				atomic.LoadInt64(&kafkaMessageCount),
				totalUpdateCount)

		case <-staleTimer.C:
			s := time.Now().UTC()
			logDebug("heartBeatDataWorker: Processing stale device removal")

			updateCount, deviceCount := staleDeviceProcess(false)
			e := time.Now().UTC()
			logInfo("heartBeatDataWorker: Completed stale device removal of %v of %v devices in %.3f seconds - forced %v",
				updateCount,
				deviceCount,
				e.Sub(s).Seconds(),
				false)

		case <-flushTimer.C:
			s := time.Now().UTC()
			logDebug("heartBeatDataWorker: Starting data flush")

			// Flush data and return number of records updated (not skipped)
			updated := flushData(
				toSortedArray(dbOnline),
				toSortedArray(dbOffline),
				false)
			totalUpdateCount += updated

			e := time.Now().UTC()
			logInfo("heartBeatDataWorker: Completed data flush of %v online, %v offline, %v updated, forced %v, in %.3f seconds",
				len(dbOnline),
				len(dbOffline),
				updated,
				false,
				e.Sub(s).Seconds())

			// Reset the storage
			dbOnline = make(map[string]bool)
			dbOffline = make(map[string]bool)
		}
	}
}

func flushData(onlineList []string, offlineList []string, force bool) (updated int64) {
	var updateCount int64 = 0

	// Process online devices
	if len(onlineList) > 0 {
		wg := new(sync.WaitGroup)
		for _, k := range onlineList {
			wg.Add(1)

			go func(g *sync.WaitGroup, m string, o bool) {
				defer g.Done()
				if trySetDeviceOnlineState(m, o, force, false) {
					atomic.AddInt64(&updateCount, 1)
				}
			}(wg, k, true)

		}
		wg.Wait()
	}

	// Process offline - do this last to make sure we catch the offline events
	if len(offlineList) > 0 {
		wg := new(sync.WaitGroup)
		for _, k := range offlineList {
			wg.Add(1)

			go func(g *sync.WaitGroup, m string, o bool) {
				defer g.Done()
				if trySetDeviceOnlineState(m, o, force, false) {
					atomic.AddInt64(&updateCount, 1)
				}
			}(wg, k, false)

		}
		wg.Wait()
	}

	return atomic.LoadInt64(&updateCount)
}

func staleDeviceProcess(force bool) (int, int) {
	// We don't want multiple instances running this process
	ok, _ := _redis.SetNX(STALE_DEVICE_MUTEX_KEY, _hostName, STALE_DEVICE_MUTEX_SECONDS)
	if !ok {
		logDebug("staleDeviceProcess: unable to acquire mutex, skipping process")
		return 0, 0
	} else {
		logDebug("staleDeviceProcess: acquired mutex successfully by %v", _hostName)
	}

	var updateCount int64 = 0
	staleDevices := getStaleFromDatabase()

	wg := new(sync.WaitGroup)
	for _, devMac := range staleDevices {
		wg.Add(1)

		go func(g *sync.WaitGroup, mac string) {
			defer g.Done()
			if trySetDeviceOnlineState(mac, false, force, false) {
				atomic.AddInt64(&updateCount, 1)
			}
		}(wg, devMac)

	}
	wg.Wait()

	return int(atomic.LoadInt64(&updateCount)), len(staleDevices)
}

func parseDevice(topicName string, payload []byte) DeviceEvent {
	atomic.AddInt64(&kafkaMessageCount, 1)

	if len(payload) == 0 {
		return DeviceEvent{MacAddress: "", Online: false}
	}

	isConnected := false
	macAddress := ""
	actTime := time.Now().UTC()

	switch topicName {
	case KAFKA_TOPIC_TELEMETRY_PUCK:
		t := PuckTelemetryMessage{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			macAddress = t.MacAddress
			isConnected = true

			if len(t.Date) > 0 {
				actTime, _ = time.Parse(time.RFC3339, t.Date)
			}
		}

	case KAFKA_TOPIC_TELEMETRY, KAFKA_TOPIC_VALVE_STATE, KAFKA_TOPIC_SYSTEM_MODE:
		t := GenericDeviceMessage{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			macAddress = t.MacAddress
			isConnected = true

			if t.Timestamp > 0 {
				actTime = time.Unix(t.Timestamp/1000, 0)
			}
		}

	case KAFKA_TOPIC_CONNECTIVITY:
		t := DeviceConnectivityMessage{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			// Connectivity topic is used ONLY for isConnected=true. isConnected=false is not reliable and makes assumptions
			if t.IsConnected && t.Timestamp > 0 {
				macAddress = t.MacAddress
				isConnected = true
				actTime = time.Unix(t.Timestamp/1000, 0)
			}
		}

	case KAFKA_TOPIC_DIRECTIVERESPONSE:
		t := DirectiveResponseMessage{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			macAddress = t.MacAddress
			isConnected = true
			actTime, _ = time.Parse(time.RFC3339, t.Timestamp)
		}

	case KAFKA_TOPIC_BULK_FILE:
		t := BulkFileSource{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			if isValidMacAddress(t.DeviceId) {
				macAddress = t.DeviceId
				actTime = t.Date
				isConnected = true
			}
		}

	case KAFKA_TOPIC_NOTIFICATIONS:
		t := NotificationEnvelopeMessage{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			msg := _notificationAlarmIdAllowed[t.Data.Alarm.AlarmId]

			if len(msg) > 0 {
				macAddress = t.MacAddress
				isConnected = true

				if t.Timestamp > 0 {
					actTime = time.Unix(t.Timestamp/1000, 0)
				}
			} else {
				logDebug("parseDevice: ignoring notification activity. %v %v", t.MacAddress, msg)
			}
		}
	case KAFKA_TOPIC_DEV_PROPS:
		t := DeviceProperties{}
		err := json.Unmarshal(payload, &t)
		if err != nil {
			logError("parseDevice: unable to deserialize message. %v %v", topicName, err.Error())
		} else {
			reason := strings.TrimSpace(strings.ToLower(t.Reason))

			if t.Timestamp > 0 && len(reason) > 0 && _propReasonWhitelist[reason] {
				macAddress = t.DeviceId
				isConnected = true
				actTime = time.Unix(t.Timestamp/1000, 0)
			}
		}
	}

	// Clean MAC address
	macAddress = strings.ToLower(strings.TrimSpace(macAddress))

	if len(macAddress) == 12 {
		return DeviceEvent{MacAddress: macAddress, Online: isConnected, Time: actTime}
	}

	return DeviceEvent{}
}

func toSortedArray(db map[string]bool) []string {
	if len(db) == 0 {
		return []string{}
	}

	sortedList := make([]string, 0)
	for k, _ := range db {
		sortedList = append(sortedList, k)
	}
	sort.Strings(sortedList)

	return sortedList
}

// Valve {"id":"b032c2ac-ea2b-11e9-afa9-428e06ef32c0","sn":"valve-state","did":"74e182167758","ts":1570580897192,"st":0,"pst":2}
// System Mode {"id":"24bed95e-ea2c-11e9-afa9-428e06ef32c0","sn":"system-mode","did":"74e182167758","ts":1570581092740,"st":2,"pst":3}
// TelemetryV3
type GenericDeviceMessage struct {
	MacAddress string `json:"did"`
	Timestamp  int64  `json:"ts"`
}

// Directive Response {"id":"d83fc9d4-ea2c-11e9-831d-e24cf2d9fb06","directive":"get-version","device_id":"a8108723e32b","time":"2019-10-09T00:36:33Z","ack_topic":"home/device/a8108723e32b/v1/directives-response/ack","data":{"os":"3.9.5"},"directive_id":"2a31c1fd-1765-4111-8227-188811460a42","snapshot":{}}
type DirectiveResponseMessage struct {
	MacAddress string `json:"device_id"`
	Timestamp  string `json:"time"`
}

// device-connectivity-status-v2 {"device_id":"4006a0a35ed5","is_connected":false,"timestamp":1573258100834}
type DeviceConnectivityMessage struct {
	MacAddress  string `json:"device_id"`
	Timestamp   int64  `json:"timestamp"`
	IsConnected bool   `json:"is_connected"`
}

// telemetry-puck-v1 {"telemetry_rssi":0,"device_id":"d8a01d689f38","fw_name":"1.0.5","telemetry_water":false,"alert_water_count":23,"fw_version":10005,"timer_wifi_ap_timeout":600000,"device_uuid":"16cdca53-e893-42a5-bc65-b0e9d9d451d2","wifi_sta_mac":"D8:A0:1D:68:9F:38","telemetry_battery_voltage":3.308000087738037,"telemetry_humidity":29.410240173339844,"serial_number":"FA347017CBCU","wifi_sta_ssid":"Anibal Lagarcone","telemetry_temperature":24.116119384765625,"timer_alarm_active":10,"reason":"heartbeat","button_click_count":4,"pairing_state":"paired","wifi_sta_enc":"wpa2-psk","wifi_ap_ssid":"FloDetector-9f38","led_pattern":"led_blue_solid","alert_water_active":false,"alert_snooze":300,"alert_state":"inactive","beep_pattern":"off","date":"2019-12-19T00:31:44.305Z"}
type PuckTelemetryMessage struct {
	MacAddress string `json:"device_id"`
	DeviceUUID string `json:"device_uuid"`
	Date       string `json:"date"`
}

// {"date":"2020-03-02T19:34:48.421Z","key":"be50c871354c14ae46119ece1cbc2e4d","deviceId":"f4844c5f506a","source":"sqs","bucketName":"flosecurecloud-bulk-device-telemetry","sourceUri":"telemetry-v7/year=2020/month=03/day=02/hhmm=1925/deviceid=f4844c5f506a/f4844c5f506a.6c315e98a1ac02890d1ed5a706c4e619ed7235758207235898319a9f4a7841ae.7.telemetry","schemaVersion":"v7"}
type BulkFileSource struct {
	Key        string    `json:"key"`
	Source     string    `json:"source"`
	BucketName string    `json:"bucketName"`
	SourceUri  string    `json:"sourceUri"`
	DeviceId   string    `json:"deviceId"`
	Date       time.Time `json:"date"`
}

// notifications-v2 {"id":"964b4508-340b-11ea-a478-a81087236440","data":{"snapshot":{"efdl":6137.3557499999997,"efd":0.0,"tmax":226.0,"t":74.00000061319993,"efl":964.91727961390404,"ftl":15.554658009987399,"p":13.262738497430608,"o":0,"m":0,"f":0.0,"sw2":0,"sw1":1,"sm":2,"tz":"US/Pacific","lt":"16:44:55","tmin":36.0,"ef":0.0,"pmax":150,"frl":15.554658009987399,"ft":54.695887278730034,"fr":0,"zm":1,"pmin":20.0},"alarm":{"defer":0.0,"reason":15,"sens":10,"info":{"in_schedule":false,"shutoff_epoch_sec":-1,"flosense_shutoff_enabled":null,"shutoff_triggered":false,"flosense_shutoff_level":null,"flosense_strength":null},"ht":1578703495800,"acts":null}},"ts":1578703496042,"did":"a81087236440"}
type NotificationEnvelopeMessage struct {
	MacAddress string                  `json:"did"`
	Timestamp  int64                   `json:"ts"`
	Data       NotificationDataMessage `json:"data"`
}

type NotificationDataMessage struct {
	Alarm NotificationAlarmMessage `json:"alarm"`
}
type NotificationAlarmMessage struct {
	AlarmId int `json:"reason"`
}

// device-properties-pub-v1 {"id":"cad64320-5cbe-11ea-9329-28ec9a985493","request_id":"28ec9a985493","device_id":"28ec9a985493","timestamp":1583178510480,"reason":"set","properties":{"fw_ver":"4.2.13","mender_host":"https://mender.flotech.co","player_action":"disabled","player_flow":0,"reboot_count":19,"system_mode":2,"valve_state":1,"wifi_rssi":-39,"zit_manual_count":0}}
type DeviceProperties struct {
	Id        string `json:"id,omitempty"`
	RequestId string `json:"request_id,omitempty"`
	DeviceId  string `json:"device_id,omitempty"`
	Timestamp int64  `json:"timestamp,omitempty"`
	Reason    string `json:"reason,omitempty"`
}

func validDate(date time.Time) bool {
	if date.Year() <= 2000 || date.Year() >= 2100 {
		return false
	}

	cutOffBefore := time.Now().UTC().Add(-5 * time.Minute).Truncate(time.Second)
	cutOffAfter := time.Now().UTC().Add(5 * time.Minute).Truncate(time.Second)

	if date.UTC().Before(cutOffBefore) || date.UTC().After(cutOffAfter) {
		return false
	}

	return true
}
