package main

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/google/uuid"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
)

const (
	KAFKA_TOPIC_TELEMETRY_FILES string = "bulk-telemetry-files"
	SQS_BATCH_LIM               int    = 10
	SQS_WAIT_TIMEOUT            int    = 20 // 20 is max
)

type AwsSnsModel struct {
	Type      string    `json:"type"`
	MessageId string    `json:"messageId"`
	TopicArn  string    `json:"topicArn"`
	Subject   string    `json:"subject"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
	Signature string    `json:"signature"`
}

type AwsEventRecordCollectionModel struct {
	Records []AwsEventRecordModel
}

type AwsEventRecordModel struct {
	EventVersion string
	EventSource  string
	AwsRegion    string
	EventTime    time.Time
	EventName    string
	S3           AwsS3EventModel
}

type AwsS3EventModel struct {
	S3SchemaVersion string
	ConfigurationId string
	Bucket          AwsS3BucketInfo
	Object          AwsS3ObjectInfoModel
}

type AwsS3BucketInfo struct {
	Name string
	Arn  string
}

type AwsS3ObjectInfoModel struct {
	Key  string
	Size int64
	ETag string
}

var (
	SQS_WAIT_NOT               = 1  //how long to wait in ns in between fetching sqs batches
	SQS_IGNORE_OLDER_THAN_DAYS = 33 //all items with date older than this will be logged & ignored at SQS level
	SQS_IGNORE_OLDER_THAN_DUR  time.Duration
	SQS_MAX_BATCH              int64 = 10
	SQS_MIN_BATCH              int64 = 4
	SQS_PULL_MSG_TIMEOUT       int64 = 90
	SQS_PULL_THREADS                 = 10
	SQS_MSG_DONE_TYPICAL             = time.Duration(250) * time.Millisecond
	SQS_DEDUPLICATE                  = false //use redis setnx to de-dup sqs message, should not be necessary unless we can't process the sqs ingestion in time, enable on high SQS queue only!
)

var (
	_sqsSvc    *sqs.SQS
	_kafkaSqs  *KafkaConnection
	_sqsUrl    string
	_sqsDupKey KeyPerDuration
	_sqsDupDur time.Duration
	_sqsCh     chan *sqs.Message
)

func init() {
	if s, e := strconv.Atoi(getEnvOrDefault("SQS_WAIT_NOT", "")); e == nil && s >= 0 {
		SQS_WAIT_NOT = s
	}
	if d, e := strconv.Atoi(getEnvOrDefault("SQS_IGNORE_OLDER_THAN_DAYS", "")); e == nil && d > 0 {
		SQS_IGNORE_OLDER_THAN_DAYS = d
	}
	logNotice("SQS_IGNORE_OLDER_THAN_DAYS=%v", SQS_IGNORE_OLDER_THAN_DAYS)
	SQS_DEDUPLICATE = strings.EqualFold(getEnvOrDefault("SQS_DEDUPLICATE", ""), "true")

	if n, _ := strconv.Atoi(getEnvOrDefault("SQS_MAX_BATCH", "")); n > 0 {
		if n > SQS_BATCH_LIM {
			n = SQS_BATCH_LIM
		}
		SQS_MAX_BATCH = int64(n)
	}
	logInfo("SQS_MAX_BATCH=%v", SQS_MAX_BATCH)
	if n, _ := strconv.Atoi(getEnvOrDefault("SQS_MIN_BATCH", "")); n > 0 {
		SQS_MIN_BATCH = int64(n)
	}
	logInfo("SQS_MIN_BATCH=%v", SQS_MIN_BATCH)
	SQS_IGNORE_OLDER_THAN_DUR = time.Duration(SQS_IGNORE_OLDER_THAN_DAYS*24) * time.Hour

	if msgVisible, _ := strconv.Atoi(getEnvOrDefault("SQS_PULL_MSG_TIMEOUT", "")); msgVisible > 0 {
		SQS_PULL_MSG_TIMEOUT = int64(msgVisible)
	}
	logNotice("SQS_PULL_MSG_TIMEOUT=%v", SQS_PULL_MSG_TIMEOUT)

	if strings.EqualFold(getEnvOrDefault("SQS_LOCAL_KEY_DEDUP", ""), "true") {
		var SQS_LOCAL_KEY_DEDUP_SEC int64 = 5 * 60 //5min default
		{
			const dedupMax = 30 * 60 //30min
			if dedupSec, _ := strconv.Atoi(getEnvOrDefault("SQS_LOCAL_KEY_DEDUP_SEC", "")); dedupSec > 0 {
				if dedupSec > dedupMax {
					dedupSec = dedupMax
				}
				SQS_LOCAL_KEY_DEDUP_SEC = int64(dedupSec)
			}
		}
		flushDur := time.Duration(SQS_LOCAL_KEY_DEDUP_SEC) * time.Second
		_sqsDupKey = CreateKeyPerDuration(flushDur)
		logInfo("SQS_LOCAL_KEY_DEDUP_SEC=%v", SQS_LOCAL_KEY_DEDUP_SEC)
		_sqsDupDur = (flushDur / 2) - (time.Millisecond * 2)
	} else {
		logNotice("SQS_LOCAL_KEY_DEDUP=false")
	}

	if sqsThread, _ := strconv.Atoi(getEnvOrDefault("SQS_PULL_THREADS", "")); sqsThread > 0 {
		SQS_PULL_THREADS = sqsThread
	}
	// channel mem has space for +1 to ensure there's always more work than workers, dropped work will be returned to SQS over time
	chBuf := math.Max(1, math.Floor(float64(SQS_PULL_THREADS)/6)) //ensure a small buffer to not starve the threads, min value of 1
	_sqsCh = make(chan *sqs.Message, SQS_PULL_THREADS+int(chBuf))
	logNotice("SQS_PULL_THREADS=%v [buf=%v]", SQS_PULL_THREADS, chBuf)

	if msgDur, _ := time.ParseDuration(getEnvOrDefault("SQS_MSG_DONE_TYPICAL", "")); msgDur >= time.Millisecond {
		SQS_MSG_DONE_TYPICAL = msgDur
	}
	logInfo("SQS_MSG_DONE_TYPICAL=%v", SQS_MSG_DONE_TYPICAL)
}

func startSqsReader() {
	kafkaProd, err := OpenKafka(_kafkaCn, nil)
	if err != nil {
		logError("startSqsReader: unable to connect to Kafka. %v", err.Error())
		signalExit()
	}
	_kafkaSqs = kafkaProd

	svc := sqs.New(_session) //reuse from main
	queueNameData, err := svc.GetQueueUrl(&sqs.GetQueueUrlInput{QueueName: aws.String(_sqsNameBulkFile)})
	if err != nil {
		logError("startSqsReader: unable to get queue url. %v %v", _sqsNameBulkFile, err.Error())
		signalExit()
		return
	}
	if queueNameData == nil || queueNameData.QueueUrl == nil || len(queueNameData.String()) == 0 {
		logError("startSqsReader: queue url is nil/empty. %v", _sqsNameBulkFile)
		signalExit()
		return
	}
	_sqsSvc = svc
	_sqsUrl = *queueNameData.QueueUrl
	if SQS_PULL_THREADS > 0 {
		logNotice("startSqsReader: OK. Items older than %v days will be ignored!", SQS_IGNORE_OLDER_THAN_DUR.Hours()/24)
		go pollSqs()
		for i := 0; i < SQS_PULL_THREADS; i++ {
			go sqsWorker()
		}
	} else {
		logWarn("startSqsReader: SQS_PULL_THREADS=0. SQS pull is DISABLED!")
	}
}

func sqsPing() error {
	if _sqsSvc == nil {
		return _log.Warn("sqs not initiated")
	}
	var (
		req = sqs.GetQueueAttributesInput{
			AttributeNames: []*string{aws.String("All")},
			QueueUrl:       aws.String(_sqsUrl),
		}
		_, e = _sqsSvc.GetQueueAttributes(&req)
	)
	_log.IfErrorF(e, "sqsPing")
	return e
}

func pollSqs() {
	logInfo("pollSqs: Started")
	var (
		maxBatch = SQS_MAX_BATCH
		//lastQueueCount = _kafkaSqs.Producer.Len()
		input = sqs.ReceiveMessageInput{
			QueueUrl:          aws.String(_sqsUrl),
			WaitTimeSeconds:   aws.Int64(int64(SQS_WAIT_TIMEOUT)),
			VisibilityTimeout: aws.Int64(SQS_PULL_MSG_TIMEOUT),
		}
	)
	for {
		if _sqsCh == nil || atomic.LoadInt32(&_cancel) > 0 {
			return
		}
		input.ReceiveRequestAttemptId = aws.String(uuid.New().String())
		input.MaxNumberOfMessages = aws.Int64(maxBatch)
		output, err := _sqsSvc.ReceiveMessage(&input)
		if err != nil {
			logError("pollSqs: failed to fetch sqs message. %v", err.Error())
			time.Sleep(time.Second)
			continue
		}

		for _, message := range output.Messages {
			if _sqsCh == nil || atomic.LoadInt32(&_cancel) > 0 {
				return
			}
			_sqsCh <- message
		}
		if SQS_WAIT_NOT > 0 {
			time.Sleep(time.Duration(SQS_WAIT_NOT) * time.Microsecond) //1_000 microsecond in 1 millisecond
		}
	}
	logNotice("pollSqs: Stopped")
}

var _sqlWorkerCounter int32 = 0

func sqsWorker() {
	workerId := fmt.Sprintf("%p_%v", _sqsSvc, atomic.AddInt32(&_sqlWorkerCounter, 1))
	logInfo("sqsWorker[%v]: start", workerId)
	for _sqsCh != nil && atomic.LoadInt32(&_cancel) == 0 {
		processSqsMessage(<-_sqsCh, workerId)
	}
	logNotice("sqsWorker[%v]: exit", workerId)
}

func processSqsMessage(message *sqs.Message, workerId string) {
	if message == nil || message.Body == nil {
		return
	}
	defer panicRecover(_log, "processSqsMessage: [%v] %v", workerId, message)

	var (
		now       = time.Now().UTC()
		bodyBytes = []byte(*message.Body) //raw sqs payload
		sns       = AwsSnsModel{}
		err       = json.Unmarshal(bodyBytes, &sns)
	)
	if err != nil {
		logWarn("processSqsMessage: [%v] unable to deserialize AwsSnsModel. %v", workerId, err.Error())
		return
	} else if len(sns.Message) < 32 {
		logWarn("processSqsMessage: [%v] sns message is empty", workerId)
		return
	}
	rec := AwsEventRecordCollectionModel{}
	if err = json.Unmarshal([]byte(sns.Message), &rec); err != nil {
		logWarn("processSqsMessage: [%v] Message Deserialization | sqs=%v %v", workerId, *message.MessageId, err.Error())
		return
	}

	for _, r := range rec.Records {
		if len(r.S3.Object.Key) == 0 || len(r.S3.Bucket.Name) == 0 {
			logWarn("processSqsMessage: [%v] s3 object key or bucket is empty | sqs=%v", workerId, *message.MessageId)
			continue
		}

		f := BulkFileSource{}
		f.Date = r.EventTime.UTC()
		f.Source = "sqs"
		f.BucketName = r.S3.Bucket.Name
		f.SourceUri, f.SchemaVersion, f.DeviceId = parseS3ObjectKey(r.S3.Object.Key)
		f.Key = calcBulkFileSourceHash(&f)

		if dt := f.DateBucket(); dt.Year() < 2021 {
			logInfo("processSqsMessage: [%v] skipping s3 object with bad date %v", workerId, f)
			continue
		} else if old := now.Sub(dt); old > SQS_IGNORE_OLDER_THAN_DUR {
			logInfo("processSqsMessage: [%v] skipping s3 object at %v days old > %v max | sqs=%v md5=%v | %v",
				workerId, old.Hours()/24, SQS_IGNORE_OLDER_THAN_DAYS, *message.MessageId, *message.MD5OfBody, f)
			continue
		}
		checkAndPubItem(message, &f, workerId)
	}

	d := sqs.DeleteMessageInput{
		QueueUrl:      aws.String(_sqsUrl),
		ReceiptHandle: message.ReceiptHandle,
	}
	if _, err = _sqsSvc.DeleteMessage(&d); err != nil {
		logWarn("processSqsMessage: [%v] error removing sqs=%v | %v", workerId, *message.MessageId, err.Error())
	} else if _log.MinLevel == 0 {
		logTrace("processSqsMessage: [%v] deleted sqs=%v", workerId, *message.MessageId)
	}
}

func canPublishSqsFile(key, srcUri string) (bool, error) {
	if SQS_DEDUPLICATE {
		return _redis.SetNX(key, srcUri, RECENT_DUP_TIMEOUT)
	}
	return true, nil
}

func checkAndPubItem(m *sqs.Message, f *BulkFileSource, workerId string) {
	var (
		key    = "btc-tlm:sqs:" + f.Key
		procDt = time.Now()
	)
	if unique := sqsDupKeyCheck(key, workerId, m, f); !unique {
		logWarn("checkAndPubItem: [%v] dupKey check. mac=%v sqs=%v mdr=%v | mck=%v %v",
			workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, time.Since(procDt), key)
	} else if ok, e := canPublishSqsFile(key, f.SourceUri); e != nil {
		logWarn("checkAndPubItem: [%v] setNX check. mac=%v sqs=%v mdr=%v | snx=%v %v",
			workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, time.Since(procDt), e.Error())
	} else if ok {
		snxDur := time.Since(procDt)
		e = _kafkaSqs.Publish(KAFKA_TOPIC_TELEMETRY_FILES, f, []byte(f.DeviceId))
		if e != nil {
			logError("checkAndPubItem: [%v] error SQS message. mac=%v sqs=%v md5=%v | snx=%v kaf=%v %v",
				workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, snxDur, time.Since(procDt)-snxDur, e.Error())
		} else {
			logDebug("checkAndPubItem: [%v] processed SQS message. mac=%v sqs=%v md5=%v | snx=%v kaf=%v | dtBk=%v",
				workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, snxDur, time.Since(procDt)-snxDur, f.DateBucket().Format("2006-01-02T15:04"))
		}
	} else {
		logDebug("checkAndPubItem: [%v] RECENT_DUPLICATE (setNX) SQS message, skipping. mac=%v sqs=%v md5=%v | snx=%v %v",
			workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, time.Since(procDt), f.SourceUri)
	}
}

func sqsDupKeyCheck(key, workerId string, m *sqs.Message, f *BulkFileSource) bool {
	if _sqsDupKey == nil {
		return true
	}
	unique := _sqsDupKey.Check(key, _sqsDupDur)
	if !unique {
		logWarn("checkAndPubItem: [%v] dupKey check. mac=%v sqs=%v mdr=%v | %v",
			workerId, f.DeviceId, *m.MessageId, *m.MD5OfBody, key)
	}
	return unique
}

func calcBulkFileSourceHash(item *BulkFileSource) string {
	data := md5.Sum([]byte(item.BucketName + ":" + item.SourceUri))
	return hex.EncodeToString(data[:])
}
