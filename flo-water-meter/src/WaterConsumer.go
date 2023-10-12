package main

import (
	"container/list"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

const DEFAULT_TIMESCALE_WRITE_THREADS = 2 // WARNING: more than 2 threads might cause high CPU on TSDB, test first

// logic that subscribe to kafka and batch write to TSDB
type WaterConsumer struct {
	log            *Logger
	kaf            *KafkaConnection
	KafkaConnStr   string // Kafka connection string
	kafkaGroupId   string // Kafka group name
	writer         WaterWriter
	ch             chan AggregateTelemetry
	state          int32 // 0 == unknown, 1 == running, 2 == stopped
	writeBatchSize int   // how many inserts in a single flush batch
	writeThreads   int   // how many threads to start
	dupQueueMax    int   // maximum size for duplicate queue
}

// DefaultWaterConsumer all settings will be read from env variables, will exit process if any are missing
func DefaultWaterConsumer() *WaterConsumer {
	w, e := CreateWaterConsumer("", "", "", 0, 0)
	if e != nil {
		os.Exit(-10)
		return nil
	}
	return w
}

// CreateWaterConsumer factory method to generate a proper consumer writer, will return error if a valid consumer writer can not be generated
func CreateWaterConsumer(tsConn, kafConn, kafGroup string, writeBatchSize int, writeThreads int) (*WaterConsumer, error) {
	log := _log.CloneAsChild("H2oKafPull")
	if tsConn == "" {
		if tsConn = getEnvOrDefault(ENVVAR_TIMESCALE_DB_CN, ""); tsConn == "" {
			return nil, log.Error("CreateWaterConsumer: tsConn or %v is required", ENVVAR_TIMESCALE_DB_CN)
		}
	}
	if kafConn == "" {
		if kafConn = getEnvOrDefault(ENVVAR_KAFKA_CN, ""); kafConn == "" {
			return nil, log.Error("CreateWaterConsumer: kafConn or %v is required", ENVVAR_KAFKA_CN)
		}
	}
	if kafGroup == "" {
		if kafGroup = getEnvOrDefault(ENVVAR_KAFKA_GROUP_ID, ""); kafGroup == "" {
			return nil, log.Error("CreateWaterConsumer: kafGroup or %v is required", ENVVAR_KAFKA_GROUP_ID)
		}
	}
	if writeBatchSize < 1 {
		batchStr := getEnvOrDefault(ENVVAR_TIMESCALE_WRITE_BATCH, "")
		if n, _ := strconv.Atoi(batchStr); n > 0 {
			writeBatchSize = n
		} else {
			writeBatchSize = DEFAULT_TIMESCALE_WRITE_BATCH
		}
	}
	if writeThreads < 1 {
		threadStr := getEnvOrDefault(ENVVAR_TIMESCALE_WRITE_THREADS, "")
		if n, e := strconv.Atoi(threadStr); e == nil && n >= 0 {
			writeThreads = n
		} else {
			writeThreads = DEFAULT_TIMESCALE_WRITE_THREADS
		}
	}

	c := WaterConsumer{}
	c.log = log
	c.writer = CreateWaterWriter(tsConn, c.log)
	c.KafkaConnStr = kafConn
	c.kafkaGroupId = kafGroup + "_writer"
	c.ch = make(chan AggregateTelemetry, 1) // eventual guaranteed delivery
	c.writeBatchSize = writeBatchSize
	c.writeThreads = writeThreads
	c.dupQueueMax = writeBatchSize * writeThreads * 10 //5x the size of variable spreads

	c.log.Notice("writeBatchSize = %v", c.writeBatchSize)
	c.log.Notice("writeThreads = %v", c.writeThreads)
	c.log.Notice("kafkaGroupId = %v", c.kafkaGroupId)
	return &c, nil
}

func (c *WaterConsumer) describeState() string {
	switch currentState := atomic.LoadInt32(&c.state); currentState {
	case 1:
		return "already started"
	case 2:
		return "already stopped"
	default: // includes default 0
		return "not yet started"
	}
}

// MustStart will exit the app if there's an error
func (c *WaterConsumer) MustStart() *WaterConsumer {
	if c != nil {
		if e := c.Start(); e != nil {
			os.Exit(10)
		}
	}
	return c
}

func (c *WaterConsumer) Start() error {
	if c.writeThreads < 1 {
		c.log.Notice("Start: LOGIC DISABLED writeThreads=%v", c.writeThreads)
		return nil
	}
	if c == nil || c.ch == nil {
		return c.log.Error("Start: consumer or channel is nil")
	}
	if !atomic.CompareAndSwapInt32(&c.state, 0, 1) { //opps
		return errors.New(c.log.Notice("Start: consumer %v", c.describeState()))
	}

	var e error                        // wire up TS connection first
	if e = c.writer.Open(); e == nil { // if we can't connect to TS, no point in pulling msg from kafka
		if e = c.initKafka(); e == nil { // wire up kafka subscriber call-back here
			for i := 0; i < c.writeThreads; i++ {
				go c.telemetryAggregateWriter()
			}
			c.log.Notice("Start: OK w/ %v threads", c.writeThreads)
			return nil
		}
	}
	return c.log.Error("Start: failed => %v", e.Error())
}

func (c *WaterConsumer) Stop() error {
	if c == nil {
		return c.log.Error("Stop: consumer is nil")
	}
	if c.writeThreads < 1 { //nothing to do really
		return c.log.Error("Stop: writeThreads < 1")
	}
	if c.ch == nil {
		return c.log.Error("Stop: channel is nil")
	}
	if !atomic.CompareAndSwapInt32(&c.state, 1, 2) { //oopps
		return errors.New(c.log.Notice("Stop: consumer %v", c.describeState()))
	}
	c.kaf.Close() // close producer source first

	startWait := time.Now()
	var sleepDiffMs int64 = 0 //wait up to 5s for cleanup
	for ; len(c.ch) > 0 && sleepDiffMs < 5000; sleepDiffMs = time.Since(startWait).Milliseconds() {
		time.Sleep(time.Millisecond * 500)
	}
	if sleepDiffMs == 0 {
		time.Sleep(time.Millisecond * 500) //force small sleep so ch input from kafka does not panic
	}
	close(c.ch) // allow draining of the channel with time limit before closing

	c.writer.Close() // close destination consumer
	c.ch = nil
	c.log.Notice("Stop: OK")
	return nil
}

func (c *WaterConsumer) initKafka() error {
	if c.KafkaConnStr == "" {
		return c.log.Error("initKafka: connection string is empty")
	}
	var e error
	if c.kaf, e = OpenKafka(c.KafkaConnStr, nil); e == nil {
		_, e = c.kaf.Subscribe(c.kafkaGroupId, []string{KAFKA_TOPIC_TELEMETRY_AGGREGATE}, c.consumeAggregateSubscriber)
	}
	if e != nil {
		return c.log.Error("initKafka: failed => %v", e.Error())
	}
	c.log.Info("initKafka: OK")
	return nil
}

var _lastQsizeCheck int64 // no need to be threadsafe, only 1 consumer

// logic to process each incoming kafka message for aggregate telemetry
func (c *WaterConsumer) consumeAggregateSubscriber(item *kafka.Message) {
	if item == nil || len(item.Value) == 0 {
		return
	}

	msg := AggregateTelemetry{}
	err := json.Unmarshal(item.Value, &msg)
	if err != nil {
		c.log.Warn("consumeAggregateSubscriber: deserialization error => %v", err.Error())
		return
	}
	if !_allow.Found(msg.DeviceId) {
		return //rejected for debugging
	}
	if !isValidMacAddress(msg.DeviceId) {
		c.log.Warn("consumeAggregateSubscriber: ignore data with bad mac %v", msg.DeviceId)
		return
	}
	if c.ch != nil {
		c.log.Debug("consumeAggregateSubscriber: received for %v", msg)
		c.ch <- msg //push to ch for TS processing
	}

	c.throttleWriteBatch()
}

const KAFKA_QSIZE_CHECK_SEC = 10 //check every 10s
func (c *WaterConsumer) throttleWriteBatch() {
	if nu := time.Now().Unix(); nu-_lastQsizeCheck > KAFKA_QSIZE_CHECK_SEC {
		_lastQsizeCheck = nu
		const lt = "throttleWriteBatch: Kafka QUEUE SIZE %v. Batch=%v"
		var (
			qSize        = c.kaf.Producer.Len()
			newBatchSize = 0
			ll           = LL_DEBUG
		)
		if qSize > 1_00_000 { // 5-10x batch size
			if qSize > 1_000_000 {
				newBatchSize = DEFAULT_TIMESCALE_WRITE_BATCH * 10
			} else {
				newBatchSize = DEFAULT_TIMESCALE_WRITE_BATCH * 5
			}
			ll = LL_NOTICE
		} else if qSize > 1_000 { // double batch size
			newBatchSize = DEFAULT_TIMESCALE_WRITE_BATCH * 2
			ll = LL_INFO
		} else { // normal batch size
			newBatchSize = DEFAULT_TIMESCALE_WRITE_BATCH
		}
		if newBatchSize != c.writeBatchSize {
			c.writeBatchSize = newBatchSize
			c.log.Log(ll, lt, qSize, c.writeBatchSize)
		}
	}
}

// process wise singletons
var _writerThreadCount int32 = 0

func (c *WaterConsumer) Receive(at AggregateTelemetry) {
	c.ch <- at
}

// will pull from channel & block until it is closed & insert into TSDB on each item received
func (c *WaterConsumer) telemetryAggregateWriter() {
	threadN := atomic.AddInt32(&_writerThreadCount, 1)
	c.log.Info("telemetryAggregateWriter_%v: begin", threadN)
	defer c.log.Info("telemetryAggregateWriter_%v: end", threadN)

	time.Sleep(time.Second)
	c.log.Debug("telemetryAggregateWriter_%v: enter channel pull loop. writeBatchSize=%v", threadN, c.writeBatchSize)
	maxAttempts := c.writeBatchSize * 2
	for c.ch != nil {
		arr := make([]*AggregateTelemetry, c.writeBatchSize)
		i := 0
		for j := 0; i < c.writeBatchSize && j < maxAttempts; j++ {
			a := <-c.ch
			if !isValidMacAddress(a.DeviceId) {
				continue // ignore random empties
			}
			if c.alreadyWritten(&a) {
				if i > 0 {
					c.log.Debug("telemetryAggregateWriter_%v: DUPLICATE write flush w/ %v %v", threadN, i, a)
					arr = arr[0:i] //take a slice of what we got so far
					break          //just insert what we got
				} else {
					c.log.Trace("telemetryAggregateWriter_%v: DUPLICATE write empty EMPTY %v", threadN, a)
					continue
				}
			} else {
				c.log.Trace("telemetryAggregateWriter_%v: adding %v to batch %v", threadN, i, a)
			}
			arr[i] = &a
			i++
		}
		if i == 0 {
			c.log.Debug("telemetryAggregateWriter_%v: EMPTY FLUSH", threadN)
			time.Sleep(time.Millisecond * 997)
			continue
		}

		c.writer.Write(arr) //sync insert to TS to limit concurrency
		arr = nil
	}
}

// process wise singletons
var _dupMap = sync.Map{}
var _dupQueue = list.New()
var _dupMux = sync.RWMutex{}

// thread safe way of checking & faster than using redis
func (c *WaterConsumer) alreadyWritten(a *AggregateTelemetry) bool {
	defer recoverPanic(_log, "alreadyWritten: %v", a.DeviceId)

	k := getWriteKey(a)
	if k[0:1] == "_" {
		c.log.Trace("alreadyWritten: rejecting bad key %v", k)
		return true //bad data, just reject
	}
	var ok bool
	if _, ok = _dupMap.LoadOrStore(k, 1); ok { //exists in map previously
		return true
	} else { // does not exists in map previously
		_dupMux.Lock()
		defer _dupMux.Unlock()
		_dupQueue.PushBack(k)                 //add to queue
		if _dupQueue.Len() >= c.dupQueueMax { // queue size is bigger than it should
			el := _dupQueue.Front() // peek from the front
			if el != nil && el.Value != nil {
				_dupQueue.Remove(el)     // dequeue
				_dupMap.Delete(el.Value) // pop from map
				el.Value = nil
			}
			el = nil
		}
		return false
	}
}

const MAX_FILL_BITS = 300
const FILL_BYTES = 38

func pgConvByteArrToBitStr(arr []byte) string {
	if len(arr) < FILL_BYTES { // default empty fill
		arr = make([]byte, FILL_BYTES)
		for i := 0; i < FILL_BYTES; i++ {
			arr[i] = 255 //byte max == all 1's in binary
		}
	}
	bits := _log.sbPool.Get()
	defer _log.sbPool.Put(bits)

	for i := 0; i < len(arr); i++ {
		s := fmt.Sprintf("%08b", arr[i])
		bits.WriteString(s)
	}
	rs := bits.String()
	if c := len(rs); c > MAX_FILL_BITS {
		rs = rs[c-MAX_FILL_BITS : c]
	}
	return rs
}

func getWriteKey(a *AggregateTelemetry) string {
	return strings.ToLower(a.DeviceId) + time.Unix(a.TimeBucket/1000, 0).Format("_060102T1504")
}
