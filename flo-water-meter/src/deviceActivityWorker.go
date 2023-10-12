package main

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"sync/atomic"
	"time"

	"github.com/google/uuid"

	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

var kafkaMessageCount int64

const KAFKA_TOPIC_TELEMETRY string = "telemetry-v3"
const KAFKA_TOPIC_TELEMETRY_AGGREGATE = "telemetry-aggregate"
const KAFKA_TOPIC_BULK_TELEMETRY string = "telemetry-v3-bulk-sqs"
const KAFKA_TOPIC_VALVE_STATE string = "valve-state-v1"
const KAFKA_TOPIC_SYSTEM_MODE string = "system-mode-v1"
const ENVVAR_AUDIT_INTERVAL_DUR = "FLO_AUDIT_INTERVAL_DUR"
const ENVVAR_REFRESH_INTERVAL_DUR = "FLO_REFRESH_INTERVAL_DUR"

// Monitor activity from a device using multiple sources. If there is any activity, keep the cache up to date.
func deviceActivityWorker() {
	logInfo("Started deviceActivityWorker")
	defer logInfo("Stopped deviceActivityWorker")

	cfg := kafka.ConfigMap{
		"client.id":          uuid.New().String(),
		"bootstrap.servers":  kafkaCn,
		"group.id":           kafkaGroupId + "_activity",
		"enable.auto.commit": true,
		"auto.offset.reset":  "latest",
	}
	c, err := kafka.NewConsumer(&cfg)
	if err != nil {
		logFatal("deviceActivityWorker: Kafka connection panic: %v", err.Error())
		panic(err)
	} else {
		logInfo("deviceActivityWorker: Connected to Kafka broker(s): %v", kafkaCn)
	}
	defer c.Close() // Close connection on exit

	subTopics := []string{
		KAFKA_TOPIC_TELEMETRY,
		KAFKA_TOPIC_BULK_TELEMETRY,
		KAFKA_TOPIC_TELEMETRY_AGGREGATE,
		//"telemetry-v3-latest", //NOTE: this will cause a crash in current impl of Kafka (2 consumer of the same topic!)
		KAFKA_TOPIC_VALVE_STATE,
		KAFKA_TOPIC_SYSTEM_MODE,
	}
	if latest := getEnvOrDefault(ENVVAR_TELEMETRY_LATEST_TOPIC, ""); latest != "" {
		subTopics = append(subTopics, latest)
	}
	if err = c.SubscribeTopics(subTopics, nil); err != nil {
		logFatal("deviceActivityWorker: panic subscribing to '%v' as '%v'. %v", subTopics, kafkaGroupId, err.Error())
		panic(err)
	} else {
		logInfo("deviceActivityWorker: Listening to topics: '%v' as '%v'", subTopics, kafkaGroupId)
	}

	logInfo("deviceActivityWorker: Ready to process kafka messages")
	dev := createCacheContext(ENVVAR_REFRESH_INTERVAL_DUR, time.Minute*5, time.Minute)
	aud := createCacheContext(ENVVAR_AUDIT_INTERVAL_DUR, time.Hour*3, time.Minute*4)
	for atomic.LoadInt32(&cancel) == 0 {
		rebuildDeviceCache(c, dev, aud) //has panic recovery
	}
}

func createCacheContext(intervalEnvVar string, intervalDefault, nextOffset time.Duration) *cacheContext {
	cx := cacheContext{
		devices: make(map[string]bool),
		next:    time.Now().Truncate(time.Minute).Add(nextOffset),
	}
	if dur, e := time.ParseDuration(getEnvOrDefault(intervalEnvVar, "")); e != nil {
		cx.interval = intervalDefault
	} else {
		cx.interval = dur
	}
	logNotice("createCacheContext: %v -> %v", intervalEnvVar, cx.String())
	return &cx
}

type cacheContext struct {
	devices  map[string]bool
	next     time.Time
	interval time.Duration
}

func (cc *cacheContext) String() string {
	if cc == nil {
		return "<nil>"
	}
	return fmt.Sprintf("[devices=len(%v) next=%v interval=%v]", len(cc.devices), cc.next.Format(time.RFC3339), fmtDuration(cc.interval))
}

func rebuildDeviceCache(c *kafka.Consumer, refresh, audit *cacheContext) {
	defer recoverPanic(_log, "rebuildDeviceCache | refresh: %v | audit: %v", refresh.String(), audit.String())

	dur := time.Second * 5
	if _log.isDebug {
		dur = dur * 2
	}
	if msg, err := c.ReadMessage(dur); err == nil {
		var pname string
		if msg.TopicPartition.Topic != nil {
			pname = *msg.TopicPartition.Topic
		}
		if macAddress := parseMacAddress(pname, msg.Value); len(macAddress) == 12 { // If we have a valid mac address, add it to the lists
			if _allow.Found(macAddress) {
				if _log.isDebug {
					if _, found := refresh.devices[macAddress]; !found {
						_log.Debug("rebuildDeviceCache: ACCEPT %v", macAddress)
					}
				}
				refresh.devices[macAddress] = true
				audit.devices[macAddress] = true
			} else if _log.isDebug {
				_log.Trace("rebuildDeviceCache: REJECT %v", macAddress)
			}
		}
	} else { // The client will automatically try to recover from all errors.
		if errString := err.Error(); strings.Contains(errString, "Timed out") {
			ll := LL_DEBUG
			if _log.isDebug {
				ll = LL_TRACE
			}
			_log.Log(ll, "rebuildDeviceCache: [dur=%v] %v", dur, errString)
		} else {
			logError("rebuildDeviceCache: Consumer error: %v", errString)
		}
		time.Sleep(dur) // Pause a bit on errors
	}

	if time.Now().After(refresh.next) {
		refresh.next = time.Now().Truncate(refresh.interval).Add(refresh.interval)
		refreshDevices(refresh.devices)
		refresh.devices = make(map[string]bool)
	}
	if time.Now().After(audit.next) {
		audit.next = time.Now().Truncate(audit.interval).Add(audit.interval)
		auditDevices(audit.devices)
		audit.devices = make(map[string]bool)
	}
}

func parseMacAddress(topicName string, payload []byte) string {
	tmpCount := atomic.AddInt64(&kafkaMessageCount, 1)
	if _log.isDebug {
		logTrace("parseMacAddress: processed %v kafka messages", tmpCount)
	}
	if len(payload) == 0 {
		return ""
	}

	macAddress := ""
	switch topicName {
	case KAFKA_TOPIC_TELEMETRY, KAFKA_TOPIC_BULK_TELEMETRY, "telemetry-v3-latest":
		t := TelemetryV3{}
		if err := json.Unmarshal(payload, &t); err != nil {
			logError("parseMacAddress: unable to deserialize %q message. %v", topicName, err.Error())
		} else if len(t.MacAddress) == 12 && (t.GPM > 0 || t.UseGallons > 0) {
			macAddress = t.MacAddress
		}
	case KAFKA_TOPIC_TELEMETRY_AGGREGATE:
		t := AggregateTelemetry{}
		if err := json.Unmarshal(payload, &t); err != nil {
			logError("parseMacAddress: unable to deserialize %q message. %v", topicName, err.Error())
		} else if len(t.DeviceId) == 12 && (t.GpmSum > 0 || t.UseGallons > 0 || t.SecondsFlo > 0) {
			macAddress = t.DeviceId
		}
	case KAFKA_TOPIC_VALVE_STATE:
		t := ValveStateMessage{}
		if err := json.Unmarshal(payload, &t); err != nil {
			logError("parseMacAddress: unable to deserialize %q message. %v", topicName, err.Error())
		} else if len(t.MacAddress) == 12 {
			macAddress = t.MacAddress
		}
	case KAFKA_TOPIC_SYSTEM_MODE:
		t := SystemModeMessage{}
		if err := json.Unmarshal(payload, &t); err != nil {
			logError("parseMacAddress: unable to deserialize %q message. %v", topicName, err.Error())
		} else if len(t.MacAddress) == 12 {
			macAddress = t.MacAddress
		}
	}
	return strings.ToLower(macAddress)
}

func canReprocessYesterday(mac string) bool {
	now := time.Now().UTC()
	oneDay := time.Hour * 24
	yesterday := now.Truncate(oneDay).Add(-oneDay)
	exp, _ := time.ParseDuration(getEnvOrDefault(ENVVAR_AUDIT_INTERVAL_DUR, "6h"))
	exp = exp * 2
	if exp < time.Hour {
		exp = time.Hour * 6
	}
	k := fmt.Sprintf("watermeter:{%v}:-1d:%v", mac, yesterday.Format("20060102"))
	if ok, e := _cache.SetNX(k, fmt.Sprint(now.Unix()), int(exp.Seconds())); e != nil {
		logWarn("canReprocessYesterday: %v error | %v", mac, e.Error())
		return false
	} else {
		return ok
	}
}

// rebuild usage data for yesterday & today
func refreshDevices(devList map[string]bool) {
	if atomic.LoadInt32(&cancel) != 0 {
		return
	}
	if len(devList) == 0 {
		logInfo("refreshDevices: Found 0 Devices to Process")
		return
	}
	// Optimize by sorting list. Other instances of the process will do the same :. reducing device cached duplicated within same minute
	sortedList := toSortedArray(devList)
	target := time.Now().UTC().Truncate(time.Hour * 24)
	us := target.Format("01-02T15")

	logDebug("refreshDevices: Processing %v Devices %v", len(sortedList), us)
	for _, k := range sortedList {
		if atomic.LoadInt32(&cancel) > 0 {
			return
		}
		atomic.AddInt64(&_qSize, 1)
		go cacheDeviceConsumption(k, target, "activityWorker", "refreshDevices: today "+us)
		if canReprocessYesterday(k) { //priodic calc of yesterday's data for delayed data
			atomic.AddInt64(&_qSize, 1)
			go cacheDeviceConsumption(k, target.Add(-24*time.Hour), "activityWorker", "refreshDevices: yesterday "+us)
		}
		backOffHighQueue()
	}
	return
}

// rebuild data for the entire history of the device
func auditDevices(devList map[string]bool) {
	if atomic.LoadInt32(&cancel) != 0 {
		return
	}
	if len(devList) == 0 {
		logInfo("auditDevices: Found 0 Devices to Process")
		return
	}
	// Optimize by sorting list. Other instances of the process will do the same thus reducing same device being cached
	// multiple times within same minute
	sortedList := toSortedArray(devList)
	logDebug("auditDevices: Processing %v Devices. %v", len(sortedList), sortedList)

	go asyncAudit(sortedList) // Run this in a separate thread
}

func asyncAudit(devices []string) {
	timeStart := time.Now()
	defer recoverPanic(_log, "asyncAudit: %v devices", len(devices))

	fm := tsWaterReader.GetDeviceFirstDataCached(false, devices...)
	for _, k := range devices {
		if atomic.LoadInt32(&cancel) > 0 {
			return
		}
		dt, _ := fm[k]
		auditDeviceLongTermCache(dt, k, "activityWorker", false)
	}
	logDebug("asyncAudit: Queued %v device(s) in %.3f sec(s)", len(devices), time.Since(timeStart).Seconds())
}

func toSortedArray(devList map[string]bool) []string {
	if len(devList) == 0 {
		return []string{}
	}

	sortedList := make([]string, len(devList))
	i := 0
	for k, _ := range devList {
		sortedList[i] = k
		i++
	}
	sort.Strings(sortedList)
	return sortedList
}

//should be compatible with v7+
type TelemetryV3 struct {
	MacAddress string  `json:"did"`
	GPM        float32 `json:"wf"`
	UseGallons float32 `json:"f"`
}

// {"id":"b032c2ac-ea2b-11e9-afa9-428e06ef32c0","sn":"valve-state","did":"74e182167758","ts":1570580897192,"st":0,"pst":2}
type ValveStateMessage struct {
	MacAddress string `json:"did"`
}

// {"id":"24bed95e-ea2c-11e9-afa9-428e06ef32c0","sn":"system-mode","did":"74e182167758","ts":1570581092740,"st":2,"pst":3}
type SystemModeMessage struct {
	MacAddress string `json:"did"`
}
