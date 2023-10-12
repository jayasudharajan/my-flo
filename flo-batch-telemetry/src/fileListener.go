package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

var _kafkaFileTopic *KafkaConnection
var _kafkaSub *KafkaSubscription

func initFileListener() {
	if _kafkaFileTopic != nil {
		return
	}
	kaf, err := OpenKafka(_kafkaCn, nil)
	if err != nil {
		logError("initFileListener: unable to connect to Kafka. %v", err.Error())
		signalExit()
		return
	}
	_kafkaFileTopic = kaf
	logInfo("initFileListener: Init DONE")
}

func startFileListener() {
	logNotice("startFileListener: BEGIN")
	initFileListener()
	launchFileThreads()

	sub, err := _kafkaFileTopic.Subscribe(_kafkaGroupId, []string{KAFKA_TOPIC_TELEMETRY_FILES}, processKafkaBulkFileMessage)
	if err != nil {
		logError("startFileListener: unable to subscribe to Kafka. %v", err.Error())
		signalExit()
		return
	}

	go func() {
		for {
			time.Sleep(time.Second)
			if atomic.LoadInt32(&_cancel) > 0 {
				logWarn("Closing FileListener kafka")
				_kafkaFileTopic.Close()
				go closeFileCh()
				return
			}
		}
	}()

	_kafkaSub = sub
	logNotice("startFileListener: COMPLETED")
}

var (
	_fileThreads = 4
	_fileCh      chan *BulkFileSource
)

func closeFileCh() {
	logInfo("closeFileCh: BEGIN")
	time.Sleep(time.Second)
	if _fileCh != nil {
		close(_fileCh)
		time.Sleep(time.Duration(3) * time.Second)
		_fileCh = nil
	}
	logInfo("closeFileCh: DONE")
}

func init() {
	if n, _ := strconv.Atoi(getEnvOrDefault("FLO_FILE_THREADS", "")); n > 0 {
		_fileThreads = n
	}

	fileBuf := 1                                                    //safer to use 1 for now, max lost of 1...
	_fileCh = make(chan *BulkFileSource, _fileThreads+int(fileBuf)) //buffer to ensure threads do not starve
	logNotice("FLO_FILE_THREADS=%v [buf=%v]", _fileThreads, fileBuf)
}

func launchFileThreads() {
	logDebug("launchFileThreads: BEGIN")
	for i := 0; i < _fileThreads; i++ {
		go fileWorker(i)
	}
	logInfo("launchFileThreads: DONE")
}

func fileWorker(threadNum int) {
	workerId := fmt.Sprintf("%p_%v", _fileCh, threadNum)
	logInfo("fileWorker[%v]: start", workerId)

	check := 3
	for _fileCh != nil && check > 0 {
		dispatchBulkFileMessage(<-_fileCh, workerId)
		if atomic.LoadInt32(&_cancel) == 1 {
			check--
		}
	}
	logNotice("fileWorker[%v]: exit", workerId)
}

func processKafkaBulkFileMessage(item *kafka.Message) {
	if item == nil || len(item.Value) == 0 {
		return
	}
	defer panicRecover(_log, "processKafkaBulkFileMessage", tryToJson(item))

	msg := BulkFileSource{}
	if err := json.Unmarshal(item.Value, &msg); err != nil {
		logError("processKafkaBulkFileMessage: bulk file deserialization error. %v", err.Error())
	} else {
		if _fileCh == nil || atomic.LoadInt32(&_cancel) > 0 {
			return
		}
		_fileCh <- &msg
	}
}

// BulkFileSource samples:
// 20200424-1858-782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv
// tlm/44/telemetry-v8.lf.csv.gz/year=2020/month=04/day=24/hhmm=1158/deviceid=782A85D15A44/782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv.gz.telemetry
// tlm-44/telemetry-v8.lf.csv.gz/year=2020/month=04/day=24/hhmm=1158/deviceid=782A85D15A44/782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv.gz.telemetry
// telemetry-v8.lf.csv.gz/year=2020/month=04/day=24/hhmm=1158/deviceid=782A85D15A44/782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv.gz.telemetry
// telemetry-v7/year=2020/month=02/day=11/hhmm=0500/deviceid=0c1c57af7707/0c1c57af7707.e0ff305ff645eca319aad3b9c5afce07ddfd11ac02386c4c8ca3d5752ca20f49.7.telemetry
type BulkFileSource struct {
	Date          time.Time `json:"date" validate:"required"`
	Key           string    `json:"key" validate:"required,min=16,max=64"`
	DeviceId      string    `json:"deviceId" validate:"required,len=12,hexadecimal"`
	Source        string    `json:"source" validate:"omitempty,max=48"`
	BucketName    string    `json:"bucketName" validate:"required,max=64"`
	SourceUri     string    `json:"sourceUri" validate:"required,min=32,max=256,endswith=.telemetry"`
	SchemaVersion string    `json:"schemaVersion" validate:"required,min=8,max=48,startswith=v"`
	//NOTE: schema version will lock in format & compression type
	AppenderName string `json:"-"`
}

func (b *BulkFileSource) FileName() string {
	arr := strings.Split(b.SourceUri, "/")
	if al := len(arr); al > 0 {
		return arr[al-1]
	}
	return ""
}

func (b *BulkFileSource) DateBucket() time.Time {
	uri := strings.ToLower(b.SourceUri)
	fs := strings.Index(uri, "/year")
	es := strings.Index(uri, "/deviceid")
	if fs > 0 && es > fs {
		dts := uri[fs+1:es] + "-00"
		dt, e := time.Parse("year=2006/month=01/day=02/hhmm=1504-07", dts)
		if e == nil && dt.Year() > 2000 {
			return dt.UTC()
		}
	}
	return time.Unix(0, 0)
}

func (b *BulkFileSource) IsV8() bool {
	if b != nil {
		if lc := strings.ToLower(b.SourceUri); strings.Contains(lc, ".8.") || strings.Contains(lc, "-v8.") {
			return true
		}
	}
	return false
}

func (b *BulkFileSource) IsHfV8() bool {
	if b != nil && strings.Contains(strings.ToLower(b.SourceUri), ".8.hf.") {
		return true
	}
	return false
}

func (b BulkFileSource) String() string {
	return tryToJson(b)
}
