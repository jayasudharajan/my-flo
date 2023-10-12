package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/base64"
	"fmt"
	"math"
	"math/bits"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/gocarina/gocsv"

	"golang.org/x/sync/semaphore"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/aws/aws-sdk-go/aws"
	parquetS3 "github.com/xitongsys/parquet-go-source/s3"
	parquetReader "github.com/xitongsys/parquet-go/reader"
	"github.com/xitongsys/parquet-go/source"

	"github.com/pkg/errors"
)

const (
	RECENT_DUP_TIMEOUT         int    = 1200
	KAFKA_AGGREGATE_TOPIC      string = "telemetry-aggregate"
	ENVVAR_FETCH_CONCURRENT_HF        = "FLO_FETCH_CONCURRENT_HF"
)

var (
	MAX_FETCH_CONCURRENT_HF int64 = 5
	_bulkCtx                context.Context
	_fetchHiResFileSem      *semaphore.Weighted
	_skipAppender           = false
	_kafkaDedup             = false
)

func init() {
	_kafkaDedup = strings.EqualFold(getEnvOrDefault("FLO_KAFKA_DEDUPLICATE", ""), "true")
	_bulkCtx = context.Background()
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_FETCH_CONCURRENT_HF, fmt.Sprint(MAX_FETCH_CONCURRENT_HF))); e == nil && n > 0 {
		MAX_FETCH_CONCURRENT_HF = int64(n)
	}
	_log.Notice("%v=%v", ENVVAR_FETCH_CONCURRENT_HF, MAX_FETCH_CONCURRENT_HF)
	_fetchHiResFileSem = semaphore.NewWeighted(MAX_FETCH_CONCURRENT_HF)

	_skipAppender = strings.EqualFold(getEnvOrDefault("FLO_SKIP_APPENDER", ""), "true")
	_log.Notice("FLO_SKIP_APPENDER=%v", _skipAppender)
}

func canProcessFileKey(file *BulkFileSource) string {
	return "mutex:batch-telemetry:process:" + file.Key
}

func canProcessFile(file *BulkFileSource) bool {
	key := canProcessFileKey(file)
	if !_kafkaDedup || _log.isDebug {
		return true
	} else if ok, _ := _redis.SetNX(key, tryToJson(file), RECENT_DUP_TIMEOUT); ok {
		return true
	}
	logDebug("canProcessFile: RECENT DUPLICATE s3://%v/%v", file.BucketName, file.SourceUri)
	return false
}

func dispatchBulkFileMessage(file *BulkFileSource, workerId string) {
	defer panicRecover(_log, "dispatchBulkFileMessage: [%v] %v", workerId, file)
	if file == nil || len(file.SourceUri) == 0 {
		logWarn("dispatchBulkFileMessage: [%v] BLANK_FILE", workerId)
		return
	} else if !canProcessFile(file) { // Check if we recently processed this file already
		return
	}

	processKafkaFile(file, _skipAppender, false, "ogProc", workerId) //download & process raw file from S3
}

var _numStartRegex = regexp.MustCompile("^[Vv]?(\\d+)") //*regexp.Regexp to parse beginning number out of a string
//Take schema version string and return the actual number, 0 is default unknown
func parseSchemaVersionNumber(schemaVersion string) int {
	if strArr := _numStartRegex.FindStringSubmatch(schemaVersion); len(strArr) < 2 {
		return 0
	} else if n, e := strconv.Atoi(strArr[1]); e != nil {
		return 0
	} else {
		return n
	}
}

const HF_MAX_BATCH_CHUNK = 10_000

func downloadHiResV8(file *BulkFileSource) ([][]*CsvRowHiRes, error) {
	var (
		raw                = make([]*CsvRowHiRes, 0)
		key                = unEscapeUrlPath(file.SourceUri)
		reader, e, cleanup = getCsvGzReaderFromS3(file.BucketName, key)
	)
	if cleanup != nil {
		defer cleanup()
	}
	if e != nil {
		//already logged
	} else if e = gocsv.Unmarshal(reader, &raw); e != nil {
		logError("downloadHiResV8: can't scan csv in %v/%v", file.BucketName, key)
	} else if rl := len(raw); rl != 0 {
		var (
			res   = make([][]*CsvRowHiRes, 0)
			chunk []*CsvRowHiRes
		)
		for i, t := range raw {
			if ts := timestampToUTCTime(t.Timestamp, false); !isValidTelemetryDate(ts) {
				logNotice("downloadHiResV8: bad date %v #%v @ %v/%v => %v", ts.Format(time.RFC3339), i, file.BucketName, key, t)
			} else {
				t.Timestamp = ts.UnixNano() / int64(time.Millisecond) //in ms?
				t.PSI = t.PSI / 10
				if i%HF_MAX_BATCH_CHUNK == 0 {
					cl := rl
					if cl > HF_MAX_BATCH_CHUNK {
						cl = HF_MAX_BATCH_CHUNK
					}
					if i > 0 {
						res = append(res, chunk)
					}
					chunk = make([]*CsvRowHiRes, 0, cl)
				}
				chunk = append(chunk, t)
			}
		}
		if len(chunk) != 0 {
			res = append(res, chunk)
		}
		raw = nil
		return res, nil
	}
	return [][]*CsvRowHiRes{}, e
}

func pullLoResFile(file *BulkFileSource) ([]TelemetryV3, error) {
	if file == nil {
		return nil, logWarn("pullLoResFile: file is nil")
	}
	var (
		start         = time.Now()
		key           = unEscapeUrlPath(file.SourceUri)
		combinedBatch = make([]TelemetryV3, 0)
	)

	switch ver := parseSchemaVersionNumber(file.SchemaVersion); ver {
	case 0:
		return nil, errors.New(logInfo("pullLoResFile: OLD_VERSION unable to parseSchemaVersionNumber. %v %v", key, file.SchemaVersion))
	case 8, 888, 998: // v888 & v998 live production hack tests
		if file.IsHfV8() {
			return nil, errors.New(logInfo("pullLoResFile: Ignored HighRes File @ %v", key))
		}
		if v8, e := downloadLoResV8(file.BucketName, key); e != nil {
			return nil, logError("pullLoResFile: error reading from s3. %v %v", key, e.Error())
		} else if len(v8) == 0 {
			return nil, logWarn("pullLoResFile: empty v8 telemetry data. %v", key)
		} else {
			combinedBatch = v8
		}
	default: // v7 is the default
		if v7, e := downloadLoResV7(file); e != nil {
			return nil, logError("pullLoResFile: error reading from s3. %v %v", key, e.Error())
		} else if len(v7) == 0 {
			return nil, logWarn("pullLoResFile: empty v7 telemetry data. %v", key)
		} else {
			combinedBatch = v7
		}
	}
	logTrace("pullLoResFile: completed did=%v %vms, file %v", file.DeviceId, time.Since(start).Milliseconds(), key)
	return combinedBatch, nil
}

func downloadLoResV7(file *BulkFileSource) ([]TelemetryV3, error) {
	var (
		key = unEscapeUrlPath(file.SourceUri)
		c   = context.TODO()
	)
	defer c.Done()
	if telemetry, err := readParquetTelemetryS3(c, S3_REGION, file.BucketName, key); err != nil {
		return nil, logError("downloadLoResV7: error reading from s3. %v %v", key, err.Error())
	} else if len(telemetry) == 0 {
		return nil, logWarn("downloadLoResV7: empty telemetry data. %v", key)
	} else {
		res := make([]TelemetryV3, 0)
		for _, t := range telemetry {
			legacyCollection := expandTelemetryV7ToV3(t)
			res = append(res, legacyCollection...)
		}
		return res, nil
	}
}

// Process raw file from S3 (all formats & compression)
func processKafkaFile(file *BulkFileSource, skipAppender, skipLastTopic bool, action, workerId string) {
	if dt := file.DateBucket(); !isValidTelemetryDate(dt) {
		logInfo("processKafkaFile: [%v] skipping s3 object with bad date %v", workerId, file)
		return
	} else if old := time.Now().UTC().Sub(dt); old > SQS_IGNORE_OLDER_THAN_DUR {
		logInfo("processKafkaFile: [%v] skipping s3 object at %v days old > %v max | %v", workerId, old.Hours()/24, SQS_IGNORE_OLDER_THAN_DAYS, file)
		return
	}

	if file.IsHfV8() {
		if !skipAppender {
			go storeHiResFile(file)
		}
		return //stop here
	}

	dlStart := time.Now() //v7 & v8 LF processing logic starts here
	legacyTelemetry, e := pullLoResFile(file)
	if e != nil {
		return
	}
	var (
		start = time.Now()
		notes = pushAggregateTelemetryToKafka(legacyTelemetry)
	)
	if !skipLastTopic {
		pushLastTelemetryToKafka(legacyTelemetry)
	}
	if !skipAppender {
		go storeLoResFile(file, legacyTelemetry)
		//storeLoResFile(file, legacyTelemetry)
	}
	logInfo("processKafkaFile: [%v] %v did=%v %vs, download took %vms, kafka queue %v, file %v | %v",
		workerId,
		action,
		file.DeviceId, time.Since(start).Milliseconds()/1000,
		start.Sub(dlStart).Milliseconds(),
		_kafkaFileTopic.Producer.Len(),
		unEscapeUrlPath(file.SourceUri),
		strings.Join(notes, " "))
}

// logic to only process v8 hi-res files, crash safe
func storeHiResFile(file *BulkFileSource) error {
	if file == nil {
		return errors.New("file is nil")
	}
	defer panicRecover(_log, "storeHiResFile: %v", file.SourceUri)
	var (
		start = time.Now()
		rows  = 0
	)
	_fetchHiResFileSem.Acquire(_bulkCtx, 1)
	defer _fetchHiResFileSem.Release(1)
	wait := time.Now()

	if a := CreateBulkAppender(_redis, _session, CONCAT_S3_BUCKET_HF, _log.Clone()); a != nil {
		if hiRes, e := downloadHiResV8(file); e != nil {
			return logWarn("storeHiResFile: can't download %v", file.SourceUri)
		} else if chunkCount := len(hiRes); chunkCount == 0 {
			return logWarn("storeHiResFile: no csv rows in %v", file.SourceUri)
		} else {
			es := make([]error, 0)
			for i, chunk := range hiRes {
				if cl := len(chunk); cl == 0 {
					continue
				} else if e = a.StoreCsv(i == 0, file, chunk, int32(cl)); e == nil {
					rows += cl
				} else {
					es = append(es, e)
				}
			}

			hiRes = nil
			ll := LL_INFO
			errLen := len(es)
			if errLen != 0 {
				ll = LL_WARN
			}
			_log.Log(ll, "storeHiResFile: completed %v %vms (%vms wait), %v rows, %v chunks, %v errors @ file s3://%v/%v",
				file.DeviceId, time.Since(wait).Milliseconds(), wait.Sub(start).Milliseconds(), rows, chunkCount, errLen, file.BucketName, file.SourceUri)
			return nil
		}
	} else {
		return logWarn("storeHiResFile: nil appender")
	}
}

func gpmToGpsBulkFix(arr []TelemetryV3) []TelemetryV3 {
	res := make([]TelemetryV3, len(arr))
	for i, t := range arr {
		t.GPM = t.UseGallons //should already be in GPS, Data team needs this field as such
		res[i] = t
	}
	return res
}

func storeLoResFile(file *BulkFileSource, legacyTelemetry []TelemetryV3) (err error) {
	if file == nil {
		return errors.New("file is nil")
	}
	if tLen := len(legacyTelemetry); tLen != 0 {
		if app := CreateBulkAppender(_redis, _session, CONCAT_S3_BUCKET_LF, _log.Clone()); app != nil {
			legacyTelemetry = gpmToGpsBulkFix(legacyTelemetry)
			err = app.StoreCsv(true, file, legacyTelemetry, int32(tLen))
		}
	}
	legacyTelemetry = nil
	file = nil
	return err
}

// Takes a V7 telemetry obj and converts it to backward compatible v3 array
func expandTelemetryV7ToV3(t Telemetry) []TelemetryV3 {
	startTime := timestampToUTCTime(t.StartTS, false)
	logDebug("expandTelemetryV7ToV3: %v %v %v", t.DeviceID, t.StartTS, startTime.Format(time.RFC3339))

	legacyCollection := make([]TelemetryV3, 0)
	for idx, _ := range t.TM {
		startTimeDelta := startTime.Add(time.Second * time.Duration(idx))
		event := t.TM[idx]

		legacy := telemetryPayloadV7toLegacyV3(&t, startTimeDelta, event)
		legacyCollection = append(legacyCollection, legacy)
	}
	return legacyCollection
}

// pipe the old array of v3 stats to new aggregate logic & push the results to Kafka
func pushAggregateTelemetryToKafka(legacyCollection []TelemetryV3) []string {
	if len(legacyCollection) == 0 {
		return []string{}
	}
	var (
		arr    = aggregateTelemetry(legacyCollection)
		eCount = 0
		bsArr  = make([]string, len(arr))
	)
	for i, a := range arr {
		logTrace("pushAggregateTelemetryToKafka: %v", a)
		e := _kafkaFileTopic.Publish(KAFKA_AGGREGATE_TOPIC, a, []byte(a.DeviceId))
		if e != nil {
			eCount++
		}
		if len(a.SecondsFill) == 0 {
			bsArr[i] = "_full_"
		} else {
			bsArr[i] = base64.StdEncoding.EncodeToString(a.SecondsFill)
		}
		bsArr[i] += ":" + strconv.Itoa(int(a.SecondsFlo))
	}
	if eCount > 0 {
		logWarn("pushAggregateTelemetryToKafka: sent %v total, %v failed", len(legacyCollection), eCount)
	}
	return bsArr
}

func nearestTimeBucket(time int64) int64 {
	return time - (time % (SLOT_SECS * 1000)) // 300,000 ms in 5 min, this will floor the time to the nearest 5min bucket
}
func makeAggKey(mac string, time int64) string {
	return strings.ToLower(mac) + "_" + strconv.FormatInt(time, 10)
}

// logic that rolls up 5min of water stats into a single entry for TSDB
func aggregateTelemetry(legacyCollection []TelemetryV3) []AggregateTelemetry {
	if len(legacyCollection) == 0 {
		return []AggregateTelemetry{}
	}
	atMap := make(map[string]*AggregateTelemetry) //bucket entries into the right aggregate
	for _, t := range legacyCollection {
		if !isValidMacAddress(t.MacAddress) || t.Timestamp <= 0 {
			continue
		}
		var (
			ts = nearestTimeBucket(t.Timestamp)
			k  = makeAggKey(t.MacAddress, ts)
			a  *AggregateTelemetry
		)
		if a = atMap[k]; a == nil { //add missing key & value
			a = &AggregateTelemetry{
				DeviceId:    t.MacAddress,
				TimeBucket:  ts,
				SecondsFill: make([]byte, SEC_SLOTS), //empty bit bucket slots filled with 0s
			}
			atMap[k] = a
		}
		if ok := setFilledBits(t.Timestamp, a.SecondsFill); !ok {
			logDebug("aggregateTelemetry: duplicate time slot mac#%v ts=%v in %v", t.MacAddress, t.Timestamp, a.SecondsFill)
			continue //skip due to duplicate time slot!
		}
		a.Seconds++

		if t.GPM > 0 {
			a.SecondsFlo++
			a.UseGallons += t.UseGallons

			a.GpmSum += t.GPM
			a.GpmMinFlo = minPositiveFloat32(a.GpmMinFlo, t.GPM)
			a.GpmMax = maxFloat32(a.GpmMax, t.GPM)
		}

		a.PsiSum += t.PSI
		a.PsiMin = minPositiveFloat32(a.PsiMin, t.PSI)
		a.PsiMax = maxFloat32(a.PsiMax, t.PSI)

		a.TempSum += t.TempF
		a.TempMin = minPositiveFloat32(a.TempMin, t.TempF)
		a.TempMax = maxFloat32(a.TempMax, t.TempF)
	}
	res := makeAggregateResults(atMap)
	return res
}

// package the map file into aggregate arrays to push to Kafka
func makeAggregateResults(atMap map[string]*AggregateTelemetry) []AggregateTelemetry {
	r := make([]AggregateTelemetry, len(atMap)) //build result array
	i := 0
	for k := range atMap {
		a := *atMap[k]
		if c := countBitsFilled(a.SecondsFill); c == SLOT_SECS {
			a.SecondsFill = []byte{} // empty array on filled bits
		}
		//rounds everything to 2 places
		a.UseGallons = roundNearFloat32(a.UseGallons, 3)

		a.GpmSum = roundNearFloat32(a.GpmSum, 3)
		a.GpmMinFlo = roundNearFloat32(a.GpmMinFlo, 2)
		a.GpmMax = roundNearFloat32(a.GpmMax, 2)

		a.PsiSum = roundNearFloat32(a.PsiSum, 3)
		a.PsiMin = roundNearFloat32(a.PsiMin, 2)
		a.PsiMax = roundNearFloat32(a.PsiMax, 2)

		a.TempSum = roundNearFloat32(a.TempSum, 3)
		a.TempMin = roundNearFloat32(a.TempMin, 2)
		a.TempMax = roundNearFloat32(a.TempMax, 2)

		r[i] = a
		i++
	}
	return r
}

// ts is unix time in ms, arr is bit mask slots in byte array for 5min, will return true if set resulted in new value
func setFilledBits(ts int64, arr []byte) bool {
	if len(arr) != int(SEC_SLOTS) {
		return false
	}
	var (
		maskPos   = int64(math.Floor(float64(ts)/1000)) % SLOT_SECS
		slotIndex = SEC_SLOTS - 1 - (maskPos / SLOT_SIZE)
		slotVal   = arr[slotIndex]
		bitPos    = maskPos % SLOT_SIZE
	)
	if bitPos == 0 {
		arr[slotIndex] = slotVal | 1
	} else {
		arr[slotIndex] = slotVal | (1 << bitPos)
	}
	ok := slotVal != arr[slotIndex]
	//logTrace("setFilledBits: maskPos %v, slotIx %v, bitPos %v, og %08b new %08b OK=%v", maskPos, slotIndex, bitPos, slotVal, arr[slotIndex], ok)
	return ok
}

func countBitsFilled(arr []byte) int {
	filled := 0
	for _, bt := range arr {
		filled += bits.OnesCount8(bt)
	}
	return filled
}

const SLOT_SECS = 300 // 300 seconds in each 5 minutes bucket
const SEC_SLOTS = 38  // 300 bits / 8 round up to 38 slots
const SLOT_SIZE = 8   // slots are in bytes or 8 bits

type AggregateTelemetry struct {
	DeviceId   string `json:"did"`                  //mac address
	TimeBucket int64  `json:"timeBucket"`           //when the time bucket starts in unix epoch MS
	Seconds    int32  `json:"seconds"`              //how many seconds are rolled up into this aggregate
	SecondsFlo int32  `json:"secondsFlo,omitempty"` //how many seconds with flowing water in this bucket

	// When bytes are full, empty strings are returned instead to save space.
	// byte array of 300 (seconds) bit mask: 300 bits / 8 = ~38 (rounded up) slots.
	SecondsFill []byte `json:"secondsFill,omitempty"`

	UseGallons float32 `json:"useGallons,omitempty"` //total water usage by gallon

	GpmSum    float32 `json:"gpmSum,omitempty"` //gallon per minute sum
	GpmMinFlo float32 `json:"gpmMin,omitempty"` //minimum gpm while water is flowing
	GpmMax    float32 `json:"gpmMax,omitempty"` //gpm max

	PsiSum float32 `json:"psiSum,omitempty"` //psi sum
	PsiMin float32 `json:"psiMin,omitempty"` //psi min
	PsiMax float32 `json:"psiMax,omitempty"` //psi max

	TempSum float32 `json:"tempSum,omitempty"` //temperature sum
	TempMin float32 `json:"tempMin,omitempty"` //temperature min
	TempMax float32 `json:"tempMax,omitempty"` //temperature max
}

func pushLastTelemetryToKafka(legacyCollection []TelemetryV3) {
	if len(legacyCollection) == 0 {
		return
	}
	//defer panicRecover(_log, "pushLastTelemetryToKafka")
	macLastMap := make(map[string]TelemetryV3)
	for _, t := range legacyCollection {
		if !isValidMacAddress(t.MacAddress) {
			continue
		}
		if cur, ok := macLastMap[t.MacAddress]; !ok {
			macLastMap[t.MacAddress] = t
		} else if t.Timestamp > cur.Timestamp { //replace max
			macLastMap[t.MacAddress] = t
		}
	}
	for _, t := range macLastMap {
		dt := time.Unix(0, t.Timestamp*1_000_000).UTC().Format(time.RFC3339)
		if e := _kafkaFileTopic.Publish(_latestTelemetryTopic, t, []byte(t.MacAddress)); e != nil {
			_log.Warn("pushLastTelemetryToKafka: %v failed @ tdt=%v | %v", t.MacAddress, dt, e.Error())
		} else {
			_log.Debug("pushLastTelemetryToKafka: OK %v @ tdt=%v", t.MacAddress, dt)
		}
	}
}

func telemetryPayloadV7toLegacyV3(ref *Telemetry, eventTime time.Time, item PayLoad) TelemetryV3 {
	// this is legacy per second data, truncate milliseconds
	evtTime := eventTime.Truncate(time.Second).UnixNano()
	if evtTime <= 0 {
		return TelemetryV3{}
	}

	rv := TelemetryV3{}
	rv.MacAddress = ref.DeviceID
	rv.Timestamp = evtTime / int64(time.Millisecond)
	rv.TempF = item.Temperature
	rv.SystemMode = item.SystemMode
	rv.ValveState = item.ValveState
	//rv.WiFiStrength = 0 // should already be 0

	ct := 0
	totalPSI := float32(0)
	totalFlowRate := float32(0)
	if len(item.HR) > 0 {
		for _, flow := range item.HR {
			totalPSI += flow.Pressure
			totalFlowRate += flow.FlowRate
			ct++
		}
	}
	if totalPSI > 0 && ct > 0 {
		rv.PSI = totalPSI / float32(ct)
	}
	if totalFlowRate > 0 && ct > 0 {
		rv.GPM = totalFlowRate / float32(ct)
	}
	if rv.GPM > 0 && ct > 0 {
		rv.UseGallons = rv.GPM / 60
	}
	return rv
}

// Reads a CSV packaged by BZ from S3 & return standard (io.Reader compatible) pointer
func getCsvGzReaderFromS3(bucket, key string) (*gzip.Reader, error, func() error) {
	downloader := s3manager.NewDownloader(_session) // create a downloader with the session and default options
	buff := &aws.WriteAtBuffer{}
	void := func() error {
		return nil
	}
	og := s3.GetObjectInput{Bucket: aws.String(bucket), Key: aws.String(key)}
	if n, err := downloader.Download(buff, &og); err != nil { // write the contents of S3 Object to memory buffer
		em := fmt.Sprintf("getCsvGzReaderFromS3: fail to download %v/%v", bucket, key)
		logWarn(em)
		return nil, errors.Wrapf(err, em), void
	} else if n == 0 {
		em := fmt.Sprintf("getCsvGzReaderFromS3: downloaded %v/%v (%v bytes)", bucket, key, n)
		logWarn(em)
		return nil, errors.New(em), void
	} else {
		logTrace("getCsvGzReaderFromS3: downloaded %v/%v (%v bytes)", bucket, key, n)
	}

	rd := bytes.NewReader(buff.Bytes())
	gzRd, err := gzip.NewReader(rd)
	if err == nil {
		return gzRd, nil, func() error {
			return gzRd.Close()
		}
	} else {
		err = errors.Wrapf(err, "getCsvGzReaderFromS3: can't create gz io reader")
		logError(err.Error())
		return nil, err, void
	}
}
func timestampToUTCTime(timestamp int64, ignoreMs bool) time.Time {
	ts := time.Unix(0, timestamp*int64(time.Millisecond)).UTC()
	if ignoreMs {
		ts = ts.Truncate(time.Second)
	}
	return ts
}

func isValidTelemetryDate(ts time.Time) bool {
	return ts.Year() >= 2000
}

// Reads a Low Resolution (1s entries) CSV packaged & return rows of v3 telemetry
// Will not panic per row of bad data, only bad file inputs
func downloadLoResV8(bucket, key string) ([]TelemetryV3, error) {
	var (
		raw                = make([]TelemetryV3, 0)
		reader, e, cleanup = getCsvGzReaderFromS3(bucket, key)
	)
	if cleanup != nil {
		defer cleanup() //should be an empty void
	}
	if e != nil {
		//already logged
	} else if e = gocsv.Unmarshal(reader, &raw); e != nil {
		logError("downloadLoResV8: can't scan csv in %v/%v", bucket, key)
	} else if rl := len(raw); rl != 0 {
		res := make([]TelemetryV3, 0, rl)
		for i, t := range raw {
			if ts := timestampToUTCTime(t.Timestamp, false); !isValidTelemetryDate(ts) {
				logNotice("downloadLoResV8: bad date %v #%v @ %v/%v => %v", ts.Format(time.RFC3339), i, bucket, key, t)
			} else {
				t.Timestamp = ts.UnixNano() / int64(time.Millisecond) //in ms?
				t.PSI = t.PSI / 10
				t.UseGallons = t.GPM / 60
				res = append(res, t)
			}
		}
		raw = nil
		return res, nil
	}
	return raw, e
}

// Reads a parquet file from S3 and returns []Telemetry slice
func readParquetTelemetryS3(ctx context.Context, region, bucket, key string) ([]Telemetry, error) {
	cfg := aws.Config{Region: aws.String(region)}
	fr, err := parquetS3.NewS3FileReader(ctx, bucket, key, &cfg)
	if err != nil {
		return nil, errors.Wrapf(err, "failed to read s3 file: %s", key)
	}

	t, e := readParquet(fr)
	if err = fr.Close(); err != nil {
		return nil, errors.Wrap(err, "failed to close")
	}
	return t, e
}

func readParquet(fr source.ParquetFile) ([]Telemetry, error) {
	pr, err := parquetReader.NewParquetReader(fr, new(Telemetry), 1)
	if err != nil {
		return nil, errors.Wrap(err, "failed to load parquet reader")
	}

	num := int(pr.GetNumRows())
	rows := make([]Telemetry, num)
	if err = pr.Read(&rows); err != nil {
		return nil, errors.Wrapf(err, "failed to load parquet file")
	}

	pr.ReadStop()
	return rows, nil
}

type Telemetry struct {
	DeviceID           string    `parquet:"name=did, type=UTF8"`
	StartTS            int64     `parquet:"name=start_ts, type=TIMESTAMP_MILLIS"`
	EndTS              int64     `parquet:"name=end_ts, type=TIMESTAMP_MILLIS"`
	TotalGallons       float32   `parquet:"name=total_gallons, type=FLOAT"`
	TotalCount         int32     `parquet:"name=total_count, type=INT_16"`
	AveragePSI         float32   `parquet:"name=avg_p, type=FLOAT"`
	AverageTemperature float32   `parquet:"name=avg_t, type=FLOAT"`
	AverageFlowRate    float32   `parquet:"name=avg_fr, type=FLOAT"`
	TM                 []PayLoad `parquet:"name=tm, type=LIST"` // up-to 300 entries. 1 data point per 1000ms
}
type PayLoad struct {
	Temperature float32 `parquet:"name=t, type=FLOAT"`   // 70-90
	SystemMode  int32   `parquet:"name=sm, type=INT_16"` // 2,3,5,7
	ValveState  int32   `parquet:"name=v, type=INT_16"`  // -1, 0,1,2,3
	HR          []Flow  `parquet:"name=hr, type=LIST"`   // up-to 10 entries. 1 data point per 100ms
}
type Flow struct {
	Pressure float32 `parquet:"name=p, type=FLOAT"`
	FlowRate float32 `parquet:"name=fr, type=FLOAT"`
}

// Schema compatible with LoRes format per csv row
type TelemetryV3 struct {
	MacAddress   string  `json:"did" csv:"did"`
	Timestamp    int64   `json:"ts" csv:"ts"`
	WiFiStrength int32   `json:"rssi" csv:"-"`
	SystemMode   int32   `json:"sm" csv:"sm"`
	ValveState   int32   `json:"v" csv:"v"`
	TempF        float32 `json:"t" csv:"t"`
	PSI          float32 `json:"p" csv:"p"`
	GPM          float32 `json:"wf" csv:"fr"`
	UseGallons   float32 `json:"f" csv:"-"`
}

func (t TelemetryV3) String() string {
	return tryToJson(t)
}

// Schema v8 HiRes format per csv row
type CsvRowHiRes struct {
	MacAddress string  `json:"did" csv:"did"`
	Timestamp  int64   `json:"ts" csv:"ts"`
	PSI        float32 `json:"p" csv:"p"`
}
