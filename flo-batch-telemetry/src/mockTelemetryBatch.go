package main

import (
	"time"

	"github.com/go-redis/redis"
)

type mockTelemetryBatch struct {
	base *mockTelemetry
	log  *Logger
}

func CreateMockTelemetryBatch(base *mockTelemetry) MockGenerator {
	return &mockTelemetryBatch{base, base.log.CloneAsChild("batch")}
}

func (m *mockTelemetryBatch) buildMetas(req *mockReq) []*BulkFileSource {
	var (
		metas = make([]*BulkFileSource, 0)
		cur   = req.Start.Truncate(req.FileDur())
		now   = time.Now().UTC()
	)
	for !cur.After(req.End) && !cur.After(now) {
		b := m.base.buildFileMeta(cur, req.MacAddr)
		metas = append(metas, &b)
		cur = cur.Add(req.FileDur())
	}
	return metas
}

func (m *mockTelemetryBatch) Generate(req *mockReq) (*mockResp, error) {
	var (
		metas = m.buildMetas(req)
		mLen  = len(metas)
	)
	if mLen == 0 {
		return nil, m.log.Warn("Generate: problem with request %v", req)
	} else {
		var (
			now   = time.Now().UTC().Format("2006-01-02T15:04:05Z")
			resp  = mockResp{req, now, metas}
			paths = make([]string, 0, mLen)
		)
		if e := m.base.storeStats(&mockStatusResp{Params: req}); e != nil {
			return nil, e
		}
		for _, m := range metas {
			paths = append(paths, m.SourceUri)
		}

		go m.generate(&resp) //side thread, actual logic to generate & upload
		m.log.Info("Generate: %v job=%v -> %v", req.MacAddr, req.JobId, paths)
		return &resp, nil
	}
}

// main logic to generate actual telemetry rows and upload to s3
func (m *mockTelemetryBatch) generate(res *mockResp) {
	defer panicRecover(m.log, "generate: %v", res.Params)
	m.log.PushScope("generate", res.Params.MacAddr, res.Params.JobId)
	defer m.log.PopScope()

	m.log.Info("Starting")
	var (
		start = time.Now()
		fLen  = len(res.Files)
		work  = mockStatusResp{
			Stats:  make([]*mockFileStatus, 0, fLen),
			Params: res.Params,
		}
	)

	for i, file := range res.Files {
		var (
			k   = canProcessFileKey(file)
			cmd = m.base.redis._client.Exists(k)
		)
		if n, e := cmd.Result(); e != nil && e != redis.Nil {
			work.Stats = append(work.Stats, &mockFileStatus{Error: e.Error(), File: file})
		} else if n > 0 {
			work.Stats = append(work.Stats, &mockFileStatus{Error: "File key already processed: " + k, File: file})
		} else {
			stats, raw := m.mockTelemetry(res, i)
			work.Stats = append(work.Stats, stats)
			if e = m.base.uploadS3(stats, raw); e != nil {
				stats.Error = e.Error()
			} else {
				stats.Status = "OK"
			}
		}
		if i%2 == 0 { //cut redis use by 1/2, uploadS3 naturally limit high use
			m.base.storeStats(&work)
		}
	}
	if fLen%2 == 0 { //ensure odd i get file store
		m.base.storeStats(&work)
	}
	m.log.Info("Done. Took %v", time.Since(start).String())
}

func (m *mockTelemetryBatch) mockTelemetry(res *mockResp, i int) (*mockFileStatus, []TelemetryV3) {
	var (
		fs   = mockFileStatus{File: res.Files[i], Aggregate: &TelemetryV3{}}
		cur  = fs.File.DateBucket()
		end  = cur.Add(res.Params.FileDur() - time.Millisecond)
		data = make([]TelemetryV3, 0, int(res.Params.FileDurS))
	)
	fs.Aggregate.MacAddress = res.Params.MacAddr
	fs.Aggregate.Timestamp = cur.Unix() * 1000 //conv to milliseconds
	fs.Aggregate.SystemMode = 2
	fs.Aggregate.ValveState = 1

	for cur.Before(end) {
		t := m.base.mockSecond(cur, res.Params)
		m.base.appendAgg(&t, &fs)

		data = append(data, t)
		cur = cur.Add(time.Second)
	}

	m.base.computeAgg(&fs)
	return &fs, data
}
