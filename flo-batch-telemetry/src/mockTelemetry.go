package main

import (
	"fmt"
	"math"
	"math/rand"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"

	"github.com/google/uuid"

	"github.com/go-redis/redis"

	"github.com/aws/aws-sdk-go/aws/session"
)

type MockGenerator interface {
	Generate(req *mockReq) (*mockResp, error)
}

type MockTelemetry interface {
	Generate(req *mockReq) (*mockResp, error)
	Check(jobId string) (*mockStatusResp, error)
}

type mockTelemetry struct {
	session *session.Session
	redis   *RedisConnection
	kafkaCn string
	kaf     *KafkaConnection
	kLock   sync.Mutex
	log     *Logger

	localProcessing bool
}

var _ensureMockPath int32

func CreateMockTelemetry(
	session *session.Session,
	redis *RedisConnection,
	kafkaCn string,
	log *Logger) MockTelemetry {

	if atomic.CompareAndSwapInt32(&_ensureMockPath, 0, 1) {
		if S3_TELEMETRY_BUCKET == "" {
			S3_TELEMETRY_BUCKET = getEnvOrDefault(ENVVAR_S3_TELEMETRY_BUCKET, "")
		}
		ensureDirPermissionOK(MOCK_PATH)
	}
	return &mockTelemetry{
		session:         session,
		redis:           redis,
		kafkaCn:         kafkaCn,
		localProcessing: strings.EqualFold(getEnvOrDefault("FLO_DEBUG_LOCAL_PROCESSING", ""), "true"),
		log:             log.CloneAsChild("mock")}
}

func (m *mockTelemetry) kafka() *KafkaConnection {
	m.kLock.Lock()
	defer m.kLock.Unlock()
	if m.kaf == nil {
		var e error
		if m.kaf, e = OpenKafka(m.kafkaCn, nil); e != nil {
			m.log.IfErrorF(e, "kafka init")
		}
	}
	return m.kaf
}

func (m *mockTelemetry) Generate(req *mockReq) (*mockResp, error) {
	var strategy MockGenerator
	if req.RealTime { //strategy pattern, expand to a switch & named (string) if more is needed or guess from req input
		strategy = CreateMockTelemetryRealtime(m)
	} else {
		strategy = CreateMockTelemetryBatch(m)
	}
	return strategy.Generate(m.ensureParams(req))
}

func (m *mockTelemetry) jobKey(jobId string) string {
	return fmt.Sprintf("mock:telemetry:{%s}", strings.ToLower(jobId))
}

const DUR_1_WEEK_S = DUR_1_DAY_S * 7

func (m *mockTelemetry) storeStats(res *mockStatusResp) error {
	var (
		k      = m.jobKey(res.Params.JobId)
		buf, e = jsonMarshalGz(res)
	)
	if e != nil {
		return m.log.IfErrorF(e, "storeStats: gz marshal %v", k)
	}
	if _, e = m.redis.Set(k, buf, DUR_1_WEEK_S); e != nil && e != redis.Nil {
		return m.log.IfErrorF(e, "storeStats: redis set %v", k)
	}
	return nil
}

//NOTE: for none random strategy, we want predictable outcomes
func (m *mockTelemetry) ensureParams(p *mockReq) *mockReq {
	if p.Gpm == nil {
		if p.Random {
			p.Gpm = &mockBound{Max: rand.Float32() * 10}
			if p.Gpm.Max < 2 {
				p.Gpm.Max = 2
			}
			p.Gpm.Min = p.Gpm.Max - 2
		} else {
			p.Gpm = &mockBound{Min: 5, Max: 10} //5-10 gpm
		}
	}
	if p.Psi == nil {
		if p.Random {
			p.Psi = &mockBound{Max: 20 + (rand.Float32() * 100)}
			p.Psi.Min = p.Psi.Max - 20
		} else {
			p.Psi = &mockBound{Max: 90, Min: 60} //60-90 psi
		}
	}
	if p.Temp == nil {
		if p.Random {
			p.Temp = &mockBound{Max: 35 + (rand.Float32() * 110)}
			p.Temp.Min = p.Temp.Max - 10
		} else {
			p.Temp = &mockBound{Max: 75, Min: 50} //50-75 F
		}
	}
	if p.Wifi == nil {
		if p.Random {
			p.Wifi = &mockBound{Min: rand.Float32() * -60}
			p.Wifi.Max = p.Wifi.Min + 20
		} else {
			p.Wifi = &mockBound{Min: -40, Max: -30} //-40 to -30 rssi
		}
	}
	return p
}

func (m *mockTelemetry) mockSecond(cur time.Time, req *mockReq) TelemetryV3 {
	t := TelemetryV3{
		MacAddress: req.MacAddr,
		Timestamp:  cur.Unix() * 1000, //conv to milliseconds
		SystemMode: 2,                 //home
		ValveState: 1,
	}
	if req.Random {
		if n := rand.Int31n(10); n%3 == 0 || n%7 == 0 {
			t.GPM = req.Gpm.GenerateRand()
		}
		t.PSI = req.Psi.GenerateRand() * 10
		t.TempF = req.Temp.GenerateRand()
		t.WiFiStrength = int32(req.Wifi.GenerateRand())
	} else {
		if s := cur.Second(); s%10 == 0 {
			t.GPM = req.Gpm.GenerateFix(cur)
		}
		t.PSI = req.Psi.GenerateFix(cur) * 10
		t.TempF = req.Temp.GenerateFix(cur)
		t.WiFiStrength = int32(req.Wifi.GenerateFix(cur))
	}

	if t.GPM > 0 {
		t.UseGallons = t.GPM / 60 //gps
		t.ValveState = 1
	}
	return t
}

func (m *mockTelemetry) getJob(jobId string) (*mockStatusResp, error) {
	k := m.jobKey(jobId)
	if buf, e := m.redis.Get(k); e != nil && e != redis.Nil {
		return nil, m.log.IfErrorF(e, "getJob: %v redis get", jobId)
	} else if len(buf) != 0 {
		res := mockStatusResp{}
		if e = jsonUnMarshalGz([]byte(buf), &res); e != nil {
			return nil, m.log.IfErrorF(e, "getJob: %v unmarshal", jobId)
		}
		return &res, nil
	}
	m.log.Notice("getJob: %v NOT_FOUND", jobId)
	return nil, nil
}

// use to check on an existing job
func (m *mockTelemetry) Check(jobId string) (*mockStatusResp, error) {
	r, e := m.getJob(jobId)
	if e == nil && r != nil {
		m.calcTotalAgg(r)
	}
	return r, e
}

func (m *mockTelemetry) calcTotalAgg(res *mockStatusResp) {
	var (
		t       = TelemetryV3{MacAddress: res.Params.MacAddr}
		statLen = float32(len(res.Stats))
	)
	if statLen == 0 {
		return
	}
	if res.Stats[0].Aggregate != nil {
		t.Timestamp = res.Stats[0].Aggregate.Timestamp
	}

	//average of average, not 100% accurate but close enough
	for _, s := range res.Stats {
		if s.File != nil {
			res.Total.Files++
		}
		if s.Error != "" {
			res.Total.Errors++
			continue
		}

		res.Total.FlowSec += s.FlowSec
		res.Total.DataSec += s.DataSec
		t.UseGallons += s.Aggregate.UseGallons
		t.PSI += s.Aggregate.PSI
		t.TempF += s.Aggregate.TempF
		t.WiFiStrength += s.Aggregate.WiFiStrength
	}

	t.PSI /= statLen
	//NOTE: same as t.GPM += (s.Aggregate.GPM / 60) * float32(s.FlowSec) //compound gps & then dividing it by total flow sec
	if res.Total.FlowSec > 0 {
		t.GPM = (t.UseGallons / float32(res.Total.FlowSec)) * 60
	}
	t.TempF /= statLen
	t.WiFiStrength = t.WiFiStrength / int32(statLen)
	t.SystemMode = -1
	t.ValveState = -1
	res.Total.Aggregate = &t
}

func (m *mockTelemetry) appendAgg(t *TelemetryV3, fs *mockFileStatus) {
	if t.GPM > 0 {
		fs.FlowSec++
		fs.Aggregate.UseGallons += t.UseGallons
	}
	fs.DataSec++
	fs.Aggregate.PSI += t.PSI / 10 //sum
	fs.Aggregate.TempF += t.TempF
	fs.Aggregate.WiFiStrength += t.WiFiStrength
}

func (m *mockTelemetry) computeAgg(fs *mockFileStatus) bool {
	if ds := float32(fs.DataSec); ds > 0 {
		if fs.FlowSec > 0 {
			fs.Aggregate.GPM = (fs.Aggregate.UseGallons / float32(fs.FlowSec)) * 60
		}
		fs.Aggregate.PSI /= ds
		fs.Aggregate.TempF /= ds
		fs.Aggregate.WiFiStrength /= fs.DataSec
		fs.Aggregate.ValveState = int32(math.Round(float64(float32(fs.Aggregate.ValveState) / ds)))
		return true
	}
	return false
}

func (m *mockTelemetry) buildFileMeta(cur time.Time, mac string) BulkFileSource {
	var (
		dts = cur.UTC().Format("year=2006/month=01/day=02/hhmm=1504")
		b   = BulkFileSource{
			Date:          cur,
			DeviceId:      strings.ToLower(mac),
			Source:        "mock",
			BucketName:    S3_TELEMETRY_BUCKET,
			SchemaVersion: "8.lf.csv.gz",
		}
		hs1, _ = mh3(b)
		hs2, _ = mh3(cur)
		hs     = hs2 + hs1
	)
	if hs == "" { //backup
		hs = strings.ReplaceAll(uuid.New().String(), "-", "")
	}

	b.SourceUri = fmt.Sprintf("tlm-%s/v%s/%s/deviceid=%s/%s.%s.%s%s",
		b.DeviceId[len(b.DeviceId)-2:], b.SchemaVersion, dts, b.DeviceId, b.DeviceId, hs, b.SchemaVersion, TELEMETRY_EXT)
	b.SourceUri = strings.ToLower(b.SourceUri)
	b.Key = calcBulkFileSourceHash(&b)
	return b
}

const MOCK_PATH = "/tmp/mock"

func (m *mockTelemetry) uploadS3(stats *mockFileStatus, raw []TelemetryV3) error {
	var (
		fileName = stats.File.FileName()
		path     = fmt.Sprintf("%s/%s", MOCK_PATH, fileName)
	)
	m.log.PushScope("uploadS3", fileName)
	defer m.log.PopScope()

	if gz, e := CreateCsvGzFile(path, m.log); e != nil {
		return e
	} else {
		gz.AppendCsv(stats.File, raw, int32(len(raw)))
		defer gz.Dispose()

		gz.mux.Lock() //ensure nothing else writes to this file while we're trying to read
		defer gz.mux.Unlock()
		if e = gz.gzw.Close(); e != nil {
			return e
		}
		_, err := gz.file.Seek(0, 0)
		if err != nil {
			return m.log.IfErrorF(err, "can't seek")
		}

		req := s3.PutObjectInput{
			Bucket:      aws.String(stats.File.BucketName),
			Key:         aws.String(stats.File.SourceUri),
			Body:        gz.file,
			ContentType: aws.String("application/x-gzip"),
			ACL:         aws.String("private"),
		}
		if _, err = s3.New(m.session).PutObject(&req); err != nil {
			return m.log.IfErrorF(err, "can't upload (%p) %v -> s3://%s/%s", gz, gz.Path(), stats.File.BucketName, stats.File.SourceUri)
		} else {
			m.log.Info("OK -> s3://%s/%s", stats.File.BucketName, stats.File.SourceUri)
			if m.localProcessing { //skip the sqs & kafka & just attempt to process now
				workerId := fmt.Sprintf("mok_%p", m)
				go func(f *BulkFileSource) {
					time.Sleep(time.Second * 2) //wait a little
					dispatchBulkFileMessage(f, workerId)
				}(stats.File)
			}
			return nil
		}
	}
}
