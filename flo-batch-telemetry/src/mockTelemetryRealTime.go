package main

import (
	"fmt"
	"time"
)

type mockTelemetryRealtime struct {
	base *mockTelemetry
	log  *Logger
}

func CreateMockTelemetryRealtime(base *mockTelemetry) MockGenerator {
	return &mockTelemetryRealtime{base, base.log.CloneAsChild("real")}
}

func (m *mockTelemetryRealtime) Generate(req *mockReq) (*mockResp, error) {
	if ok, e := m.canMock(req.MacAddr, req.End); e != nil {
		return nil, m.log.IfErrorF(e, "Generate: %v job=%v", req.MacAddr, req.JobId)
	} else if !ok {
		return nil, m.log.Warn("Generate: %v job=%v | Another process is generating real time data", req.MacAddr, req.JobId)
	}

	if e := m.base.storeStats(&mockStatusResp{Params: req}); e != nil {
		m.cleanKey(req.MacAddr)
		return nil, e
	}
	go m.generate(req)
	m.log.Info("Generate: %v job=%v", req.MacAddr, req.JobId)
	now := time.Now().UTC().Format("2006-01-02T15:04:05Z")
	return &mockResp{req, now, nil}, nil
}

func (m *mockTelemetryRealtime) mockKey(mac string) string {
	return fmt.Sprintf("mock:realtime:{%s}", mac)
}

func (m *mockTelemetryRealtime) canMock(mac string, end time.Time) (bool, error) {
	var (
		k = m.mockKey(mac)
		n = time.Now().UTC()
		v = n.Format(time.RFC3339)
	)
	return m.base.redis.SetNX(k, v, int(end.Sub(n).Seconds()))
}

//force unlocking of live telemetry mock for this device
func (m *mockTelemetryRealtime) cleanKey(mac string) error {
	_, e := m.base.redis.Delete(m.mockKey(mac))
	return m.log.IfWarnF(e, "cleanKey: %v", mac)
}

const TOPIC_REALTIME = "telemetry-v3" //not likely that this will change, it's hardcoded everywhere

func (m *mockTelemetryRealtime) newStats(req *mockReq, cur time.Time) *mockFileStatus {
	s := mockFileStatus{
		Aggregate: &TelemetryV3{
			MacAddress: req.MacAddr,
			Timestamp:  cur.Unix() * 1000,
			SystemMode: 2,
			ValveState: 1,
		},
	}
	return &s
}

func (m *mockTelemetryRealtime) generate(req *mockReq) {
	defer panicRecover(m.log, "generate: %v", req)
	m.log.PushScope("generate", req.MacAddr, req.JobId)
	defer m.log.PopScope()
	defer m.cleanKey(req.MacAddr)

	var (
		started       = time.Now()
		cur           = started.UTC().Truncate(time.Second)
		kaf           = m.base.kafka()
		res           = mockStatusResp{Params: req, Stats: make([]*mockFileStatus, 0)}
		sec     int32 = 0
		files   int32 = 0
		errors  int32 = 0
		arr           = make([]TelemetryV3, 0)
	)
	if kaf == nil {
		m.log.Error("can't init Kafka for %v", req.MacAddr)
		m.base.storeStats(&res)
		return
	}

	m.log.Info("Starting in %v", req.Start.Sub(cur).String())
	for cur.Before(req.End) {
		if sl := len(res.Stats); sl == 0 || (res.Stats[sl-1].DataSec > 0 && sec%req.FileDurS == 0) {
			res.Stats = append(res.Stats, m.newStats(req, cur))
			errors = 0
		}
		if cur.After(req.Start) {
			t := m.base.mockSecond(cur, req)

			t.PSI /= 10 //take this down 10x for kafka because we are publishing per 1/s instead of 10
			if e := kaf.Publish(TOPIC_REALTIME, &t, []byte(req.MacAddr)); e != nil {
				m.log.IfWarnF(e, t.String())
				errors++
			} else {
				ll := LL_TRACE
				if sec%10 == 0 {
					ll = LL_DEBUG
				}
				m.log.Log(ll, "%v -> %v", TOPIC_REALTIME, t)
			}

			t.PSI *= 10 //bing it up 10x again
			arr = append(arr, t)
			sec++
			fs := res.Stats[files]
			m.base.appendAgg(&t, fs)
		}
		if sec%req.FileDurS == 0 {
			if fs := res.Stats[files]; m.computeUploadAgg(fs, arr, req.NoUpload) { //reset
				arr = arr[:0] //shrink slice
				sec = 0
				files++
				m.storeStats(&res, errors)
			}
		} else if sec%15 == 0 { //store stats every 15s also
			m.storeStats(&res, errors)
		}
		time.Sleep(time.Second) //generate at most 1 item per s
		cur = time.Now().UTC()
	}

	if sl := len(res.Stats); sl > 0 {
		if fs := res.Stats[sl-1]; fs.DataSec == 0 {
			res.Stats = res.Stats[:sl-1] //cut the last empty stats off
		} else { //do last aggregate comp
			m.computeUploadAgg(fs, arr, req.NoUpload)
		}
	}
	m.storeStats(&res, errors)
	m.log.Info("Done. Took %v", time.Since(started).String())
}

func (m *mockTelemetryRealtime) computeUploadAgg(fs *mockFileStatus, arr []TelemetryV3, noUpload bool) bool {
	if m.base.computeAgg(fs) {
		if fs.File == nil && len(arr) != 0 { //generate meta & upload s3
			var (
				ts   = time.Unix(arr[0].Timestamp/1000, 0).UTC() //this could be arr[0].Timestamp
				meta = m.base.buildFileMeta(ts, fs.Aggregate.MacAddress)
			)
			fs.File = &meta
			if noUpload {
				m.log.Debug("computeUploadAgg: skipping upload of %v", fs.File)
			} else {
				m.base.uploadS3(fs, arr)
			}
		}
		return true
	}
	return false
}

func (m *mockTelemetryRealtime) storeStats(res *mockStatusResp, errors int32) error {
	sl := len(res.Stats)
	if sl > 0 {
		fs := res.Stats[sl-1]
		if errors > 0 {
			fs.Error = fmt.Sprintf("%v kafka publish errors", errors)
		} else {
			fs.Status = "OK"
		}
		m.log.Debug("storeStats: FLUSH | %v errors, %v stats | last %v", errors, sl, tryToJson(fs.Aggregate))
	} else {
		m.log.Debug("storeStats: FLUSH | %v errors, %v stats", errors, sl)
	}
	return m.base.storeStats(res)
}
