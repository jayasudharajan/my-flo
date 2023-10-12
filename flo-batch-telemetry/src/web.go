package main

import (
	"errors"
	"fmt"
	"math"
	"math/rand"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/go-redis/redis"

	"github.com/gin-gonic/gin"

	_ "gitlab.com/flotechnologies/flo-batch-telemetry/docs"
)

func registerRoutes(ws *WebServer) {
	ws.router.GET("/", func(c *gin.Context) {
		NewHandler(ws).Ping(c)
	})
	ws.router.GET("/ping", func(c *gin.Context) {
		NewHandler(ws).Ping(c)
	})
	ws.router.POST("/ping", func(c *gin.Context) {
		NewHandler(ws).Ping(c) //deep ping for debugging
	})
	ws.router.POST("/append/reprocess", func(c *gin.Context) {
		NewHandler(ws).ReProcessBulkS3(c)
	})
	ws.router.GET("/append/reprocess/stats", func(c *gin.Context) {
		NewHandler(ws).ReProcessBulkStats(c)
	})
	ws.router.DELETE("/append/reprocess/stats", func(c *gin.Context) {
		NewHandler(ws).RemoveReBulkStats(c)
	})
	ws.router.GET("/telemetry/mock/:jobId", func(c *gin.Context) {
		NewHandler(ws).MockStatus(c)
	})
	ws.router.POST("/telemetry/mock", func(c *gin.Context) {
		NewHandler(ws).MockData(c)
	})
	ws.router.POST("/telemetry/reprocess", func(c *gin.Context) {
		NewHandler(ws).ReProcess(c)
	})
	ws.router.DELETE("/telemetry/reprocess", func(c *gin.Context) {
		NewHandler(ws).ReProcessTruncate(c)
	})
	ws.router.GET("/telemetry/reprocess/stats", func(c *gin.Context) {
		NewHandler(ws).ReProcessStats(c)
	})
	ws.router.DELETE("/telemetry/reprocess/stats", func(c *gin.Context) {
		NewHandler(ws).ReProcessStatsRemove(c)
	})
	ws.router.GET("/recover/stats", func(c *gin.Context) {
		NewHandler(ws).RecoverQueueCount(c)
	})
	ws.router.DELETE("/recover", func(c *gin.Context) {
		NewHandler(ws).RecoverQueueTruncate(c)
	})
}

type ApiHandler struct {
	ws  *WebServer
	log *Logger
}

func NewHandler(ws *WebServer) *ApiHandler {
	return &ApiHandler{
		ws:  ws,
		log: ws.log.CloneAsChild("Handler"),
	}
}

// Ping godoc
// @Summary check the health status of the service and list its config data
// @Description returns status of the service
// @Tags system
// @Accept  json
// @Produce  json
// @Success 200
// @Router /ping [get]
// PingHandler is the handler for healthcheck aka ping
func (_ *ApiHandler) Ping(c *gin.Context) {
	var (
		env  = getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local"))
		dur  = time.Since(_start)
		code = 200
		rv   = map[string]interface{}{
			"date":           time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":            APP_NAME,
			"status":         "ok",
			"commit":         _commitSha,
			"commitTime":     _commitTime,
			"host":           _hostName,
			"uptime":         int64(dur.Seconds()),
			"uptimeDur":      fmt.Sprint(dur),
			"env":            env,
			"goRoutineCount": runtime.NumGoroutine(),
		}
	)
	if c.Request.Method == "POST" { //deep ping
		oks := make(map[string]string)
		appendPing(oks, "redis", _redis.Ping)
		appendPing(oks, "sqs", sqsPing)
		if _reProc != nil {
			appendPing(oks, "kafka", _reProc.PingKafka)
		}
		if _reBulkPath != nil {
			appendPing(oks, "s3", _reBulkPath.PingS3)
		}
		//TODO: add SNS ping

		rv["checks"] = oks
		for _, v := range oks {
			if v != "OK" {
				code = 503
				rv["status"] = "Unavailable"
				break
			}
		}
	}
	c.JSON(code, rv)
}

func appendPing(m map[string]string, name string, png func() error) {
	if e := png(); e != nil {
		m[name] = e.Error()
	} else {
		m[name] = "OK"
	}
}

type reProcessBulkReq struct {
	S3Paths []string    `json:"s3Paths" validate:"max=100000,dive,min=32,max=256,startswith=s3://"`
	Matches []*s3Prefix `json:"matches,omitempty" validate:"omitempty,min=1,dive"`
}

const TELEMETRY_EXT = ".telemetry"

// SplitPath separate paths for recursive processing & files for direct processing
func (r *reProcessBulkReq) SplitPath() (dirs []string, files []string) {
	dirs = make([]string, 0)
	files = make([]string, 0)
	telLen := len(TELEMETRY_EXT)
	for _, p := range r.S3Paths {
		pLen := len(p)
		if ix := strings.LastIndex(p, TELEMETRY_EXT); ix == pLen-telLen { //is file
			files = append(files, p)
		} else {
			dirs = append(dirs, p)
		}
	}
	return
}

type ReProcessRes struct {
	Params reProcessBulkReq `json:"params"`
	Paths  int              `json:"paths"`
	Files  int              `json:"files"`
	Errors []string         `json:"errors"`
}

// ReProcessBulkS3 Bulk Append S3 file godoc
// @Summary take an s3 url and re-process it for bulk append pipeline only, this will not trigger kafka messages downstream
// @Description meant for the data team's bulk re-processing only
// @Tags system
// @Accept  json
// @Produce  json
// @Success 204
// @Router /append/reprocess [get]
// Note this method will block until complete :. it only take 1 item.  Meant to be used with a shell script to distribute the load amongst containers
func (h *ApiHandler) ReProcessBulkS3(c *gin.Context) {
	req := reProcessBulkReq{}
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		h.ws.HttpError(c, 400, "Bad input", e)
	} else {
		var (
			paths, files = req.SplitPath()
			res          = ReProcessRes{Params: req}
		)
		if fl := len(files); fl > 0 {
			_reBulk.Queue(files...)
			res.Files = fl
		}
		if pl := len(paths); pl > 0 {

			if e = _reBulkPath.QueuePaths(paths...); e != nil {
				res.Errors = append(res.Errors, e.Error())
			}
			res.Paths = pl
		}

		matchedPaths := h.explodePaths(req.Matches)
		for _, m := range matchedPaths {
			if e = _reBulkPath.QueuePaths(m...); e != nil {
				res.Errors = append(res.Errors, e.Error())
			} else {
				res.Paths += len(m)
			}
		}

		c.JSON(202, res)
	}
}

func (h *ApiHandler) ReProcessBulkStats(c *gin.Context) {
	res := map[string]interface{}{
		"dirs":  _reBulkPath.Size(),
		"files": _reBulk.GetStats(),
	}
	c.JSON(200, res)
}

func (h *ApiHandler) RemoveReBulkStats(c *gin.Context) {
	_reBulk.DeleteStats()
	c.JSON(204, nil)
}

type mockBound struct {
	Min float32 `json:"min" validate:"min=0"`
	Max float32 `json:"max" validate:"min=0"`
	//Sum float32 `json:"sum" validate:"min=0"`
}

func (r mockBound) String() string {
	return tryToJson(r)
}

func (r *mockBound) Normalize(max float32) {
	if r != nil && r.Max > max {
		r.Max = max
	}
}

func (r *mockBound) GenerateRand() float32 {
	v := r.Min + rand.Float32()*(r.Max-r.Min)
	return v
}

func (r *mockBound) GenerateFix(cur time.Time) float32 {
	v := r.Min + (float32(cur.Minute()) / 10) + (float32(cur.Second()) / 100)
	if v > r.Max { //loop around
		var (
			mul  = v / r.Max
			flr  = float32(math.Floor(float64(mul)))
			diff = (mul - flr) * r.Max
		)
		v = r.Min + diff
	}
	return v
}

type mockReq struct {
	JobId    string     `json:"jobId" validate:"omitempty,max=36,min=12,alphanum"` //allow 1 to be set but it is optional
	MacAddr  string     `json:"macAddress" validate:"required,len=12,hexadecimal"`
	Start    time.Time  `json:"startDate" validate:"omitempty"`
	End      time.Time  `json:"endDate" validate:"omitempty"`
	FileDurS int32      `json:"fileDurSec" validate:"min=0,omitempty"`
	Gpm      *mockBound `json:"gpm,omitempty" validate:"omitempty,dive"`
	Psi      *mockBound `json:"psi,omitempty" validate:"omitempty,dive"`
	Temp     *mockBound `json:"temp,omitempty" validate:"omitempty,dive"`
	Wifi     *mockBound `json:"wifi,omitempty" validate:"omitempty,dive"`
	Random   bool       `json:"random"`     //NOTE: if true, will randomize data, if false, it will create a controlled test based on time bucket
	RealTime bool       `json:"realTime"`   //NOTE: if true, will push data into real time bucket & prevent another process of doing the same for this device
	NoUpload bool       `json:"noUploadS3"` //NOTE: if true, skip the uploading of S3 file, only applicable for real time mock
	//ModeSec  []int32 `json:"modeSec,omitempty" validate:"omitempty,dive,min=-1,max=5"`
	//ValveSec []int32 `json:"valveSec,omitempty" validate:"omitempty,dive,min=-1,max=3"`
}

func (m *mockReq) FileDur() time.Duration {
	return time.Duration(m.FileDurS) * time.Second
}

func (r *mockReq) Normalize() *mockReq {
	if r.JobId == "" {
		r.JobId = uuid.New().String()
	}
	r.JobId = strings.ToLower(r.JobId)
	if r.FileDur() <= 0 {
		r.FileDurS = int32((time.Minute * 5).Seconds())
	}

	if r.RealTime { //strategy switch
		r.normalizeRealTime()
	} else {
		r.normalizeBatch()
	}
	r.Start = r.Start.UTC()
	r.End = r.End.UTC()

	r.Gpm.Normalize(20)
	r.Psi.Normalize(120)
	r.Temp.Normalize(130)
	r.Wifi.Normalize(100)
	if r.Wifi != nil {
		if r.Wifi.Min > 0 {
			r.Wifi.Min *= -1
		}
		if r.Wifi.Max > 0 {
			r.Wifi.Max *= -1
		}
	}
	return r
}

func (r *mockReq) normalizeBatch() {
	if r.Start.Year() <= 1 { //auto start
		n := time.Now().UTC().Truncate(r.FileDur())
		r.Start = n.Add(-r.FileDur())
		r.End = n.Add(-time.Millisecond)
	} else {
		r.Start = r.Start.Truncate(r.FileDur())
	}

	if !r.End.After(r.Start) {
		r.End = r.Start.Add(r.FileDur() - time.Millisecond)
	} else {
		en := r.End.Truncate(r.FileDur()).Add(r.FileDur())
		if !en.After(r.Start) {
			en = en.Add(r.FileDur())
		}
		en = en.Add(-time.Millisecond)
		if en.After(r.Start) {
			r.End = en
		}
	}
}

const (
	MOCK_MAX_REAL_START_WAIT = 15 * time.Minute //maximum wait before starting real time gen
	MOCK_MAX_REAL_DUR        = 30 * time.Minute //maximum real time data duration
)

func (r *mockReq) normalizeRealTime() {
	now := time.Now().Truncate(time.Second).Add(time.Second * 2).UTC()
	if r.Start.Year() <= 1 { //auto start
		r.Start = now.Add(time.Second * 3) //start in 3s
	} else if diff := r.Start.Sub(now); diff > MOCK_MAX_REAL_START_WAIT {
		r.Start = now.Add(MOCK_MAX_REAL_START_WAIT) //don't wait beyond 15min
	}

	if !r.End.After(r.Start) { //usage for 1 min by default
		r.End = r.Start.Add(time.Minute)
	} else if r.End.Sub(r.Start) > MOCK_MAX_REAL_DUR {
		r.End = r.Start.Add(MOCK_MAX_REAL_DUR)
	}
}

func (r *mockReq) Validate() error {
	if r == nil {
		return errors.New("nil ref")
	}
	var now = time.Now().UTC()
	//expand to strategy pattern if more than 2 is needed, maybe tie in with mockTelemetry.Generate(...)
	if r.RealTime { //future only
		now = now.Add(time.Second)
		if r.Start.Year() > 1 {
			if r.Start.Before(now) {
				return errors.New("startDate can not be in the past for real time mock")
			}
		}
		if r.End.Year() > 1 {
			if !r.End.After(r.Start) {
				return errors.New("endDate is not after startDate")
			}
			if !r.End.After(now) {
				return errors.New("endDate can not be in the past for real time mock")
			}
		}
	} else { //past only
		if r.Start.Year() > 1 {
			if r.Start.After(now) {
				return errors.New("startDate can not be in the future for batch mock")
			}
		}
		if r.End.Year() > 1 {
			if !r.End.After(r.Start) {
				return errors.New("endDate is not after startDate")
			}
			if r.End.After(now) {
				return errors.New("endDate can not be in the future for batch mock")
			}
		}
	}
	return nil
}

func (m mockReq) String() string {
	return tryToJson(m)
}

type mockResp struct {
	Params *mockReq          `json:"params,omitempty"`
	Now    string            `json:"now,omitempty"`
	Files  []*BulkFileSource `json:"files,omitempty"`
}

func (r mockResp) String() string {
	return tryToJson(r)
}

func (h *ApiHandler) MockData(c *gin.Context) {
	var (
		req = mockReq{}
		res *mockResp
	)
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		h.ws.HttpError(c, 400, "Bad input", e)
	} else if e = req.Validate(); e != nil {
		h.ws.HttpError(c, 400, e.Error(), e)
	} else if res, e = _mock.Generate(req.Normalize()); e != nil {
		h.ws.HttpError(c, 500, "Generation error", e)
	} else {
		c.JSON(202, res)
	}
}

type mockStatusResp struct {
	Params *mockReq          `json:"params"`
	Stats  []*mockFileStatus `json:"fileStatus,omitempty"`
	Total  struct {
		Aggregate *TelemetryV3 `json:"aggregate,omitempty"`
		DataSec   int32        `json:"dataSec,omitempty"`
		FlowSec   int32        `json:"floSec,omitempty"`
		Errors    int32        `json:"errors,omitempty"`
		Files     int32        `json:"files,omitempty"`
	} `json:"total,omitempty"`
}

type mockFileStatus struct {
	Status    string          `json:"status,omitempty"`
	Error     string          `json:"error,omitempty"`
	File      *BulkFileSource `json:"file,omitempty"`
	Aggregate *TelemetryV3    `json:"aggregate"`
	DataSec   int32           `json:"dataSec"`
	FlowSec   int32           `json:"floSec"`
}

func (h *ApiHandler) MockStatus(c *gin.Context) {
	if jobId := c.Param("jobId"); jobId == "" {
		h.ws.HttpError(c, 400, "jobId is required", nil)
	} else if e := h.ws.validate.Value(jobId, "uuid_rfc4122", "jobId"); e != nil {
		h.ws.HttpError(c, 400, "jobId invalid", e)
	} else if res, e := _mock.Check(jobId); e != nil {
		if e == redis.Nil {
			h.ws.HttpError(c, 404, "job not found", nil)
		} else {
			h.ws.HttpError(c, 500, "status check", e)
		}
	} else {
		c.JSON(200, res)
	}
}

type s3Prefix struct {
	Shard   string  `json:"shard,omitempty" validate:"omitempty,min=1,max=6"`
	Version string  `json:"version" validate:"required,min=12,max=22"`
	Date    []int32 `json:"date" validate:"required,min=2,max=5,dive,min=0"` //[2020,4,24,11,58] -> [yyyy,MM,dd,hh,mm]
}

func (p *s3Prefix) Expandable() bool {
	return strings.Contains(p.Shard, "*")
}

func (p *s3Prefix) Clone() *s3Prefix {
	val := *p   //copy to value
	return &val //return new pointer
}

func (p *s3Prefix) SetShard(sh string) *s3Prefix {
	p.Shard = sh
	return p
}

const HEX_CHARS = "0123456789abcdef"

func (p *s3Prefix) Expand() []*s3Prefix {
	arr := make([]*s3Prefix, 0)
	if p.Shard == "*" { //expand all
		arr = append(arr, p.Clone().SetShard(""))
		arr = append(arr, p.Clone().SetShard("tlm-*").Expand()...)
		arr = append(arr, p.Clone().SetShard("tlm/*").Expand()...)
	} else if strings.Contains(p.Shard, "*") { //expand shards wildcard: tml-* or tml/*
		hex := strings.Split(HEX_CHARS, "") //should be 16
		for _, c1 := range hex {
			for _, c2 := range hex {
				sh := strings.ReplaceAll(p.Shard, "*", c1+c2)
				arr = append(arr, p.Clone().SetShard(sh))
			}
		}
	} else {
		arr = append(arr, p.Clone())
	}
	return arr
}

func (p *s3Prefix) PrefixPath() string {
	if p.Expandable() {
		return ""
	}
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	sb.WriteString("s3://")
	sb.WriteString(S3_TELEMETRY_BUCKET)
	sb.WriteString("/")
	if p.Shard != "" {
		sb.WriteString(p.Shard)
		sb.WriteString("/")
	}
	sb.WriteString(p.Version)
	for i, dv := range p.Date {
		switch i {
		case 0: //yyyy
			sb.WriteString(fmt.Sprintf("/year=%04d", dv))
		case 1: //mm
			sb.WriteString(fmt.Sprintf("/month=%02d", dv))
		case 2: //dd
			sb.WriteString(fmt.Sprintf("/day=%02d", dv))
		case 3: //hh
			sb.WriteString(fmt.Sprintf("/hhmm=%02d", dv))
		case 4: //mm
			sb.WriteString(fmt.Sprintf("%02d", dv))
		}
	}
	return sb.String()
}

type reProcessReq struct {
	S3Paths []string    `json:"s3Files,omitempty" validate:"omitempty,min=1,max=10000,dive,min=32,max=256,startswith=s3://"`
	Matches []*s3Prefix `json:"matches,omitempty" validate:"omitempty,min=1,dive"`
}

func (r *reProcessReq) Validate() error {
	es := make([]error, 0)
	if len(r.S3Paths) == 0 && len(r.Matches) == 0 {
		es = append(es, errors.New("both s3Files and matches can not be empty"))
	}
	for _, sp := range r.Matches {
		for i, dv := range sp.Date {
			switch i {
			case 0: //yyyy
				if dv < 2000 {
					es = append(es, errors.New("invalid date: year"))
				}
			case 1: //mm
				if dv < 1 || dv > 12 {
					es = append(es, errors.New("invalid date: month"))
				}
			case 2: //dd
				if dv < 1 || dv > 31 {
					es = append(es, errors.New("invalid date: day"))
				}
			case 3: //hh
				if dv < 0 || dv > 23 {
					es = append(es, errors.New("invalid date: hour"))
				}
			case 4: //mm
				if dv < 0 || dv > 59 {
					es = append(es, errors.New("invalid date: minute"))
				}
			}
		}
	}
	return wrapErrors(es)
}

type reProcessResp struct {
	Params *reProcessReq     `json:"params"`
	Files  []*BulkFileSource `json:"files"`
	Paths  []string          `json:"paths"`
	Errors []string          `json:"errors"`
}

func (r reProcessResp) String() string {
	return fmt.Sprintf("reProcessResp=(files:%v,paths:%v,errors:%v)", len(r.Files), len(r.Paths), len(r.Errors))
}

func (h *ApiHandler) ReProcess(c *gin.Context) {
	var (
		req   = reProcessReq{}
		start = time.Now()
	)
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		h.ws.HttpError(c, 400, "ReProcess: invalid params", e)
	} else if ve := req.Validate(); ve != nil {
		h.ws.HttpError(c, 400, "ReProcess: "+ve.Error(), ve)
	} else {
		resp := reProcessResp{
			Params: &req,
			Files:  make([]*BulkFileSource, 0, len(req.S3Paths)),
			Errors: make([]string, 0),
		}
		for _, url := range req.S3Paths { //extract path
			if isTelemetryFile(url) {
				if files, e := _reProc.Queue(url); e != nil {
					resp.Errors = append(resp.Errors, e.Error())
				} else {
					resp.Files = append(resp.Files, files...)
				}
			} else { //probably a path
				if e = _reProcPath.QueuePaths(url); e != nil {
					resp.Errors = append(resp.Errors, e.Error())
				} else {
					resp.Paths = append(resp.Paths, url)
				}
			}
		}

		matchedPaths := h.explodePaths(req.Matches)
		for _, m := range matchedPaths {
			if e = _reProcPath.QueuePaths(m...); e != nil {
				resp.Errors = append(resp.Errors, e.Error())
			} else {
				resp.Paths = append(resp.Paths, m...)
			}
		}

		ll := LL_NOTICE
		if len(resp.Errors) != 0 {
			ll = LL_WARN
		}
		h.log.Log(ll, "ReProcess: took=%v %v", time.Since(start), resp)
		c.JSON(202, resp)
	}
}

func (h *ApiHandler) ReProcessTruncate(c *gin.Context) {
	if n, e := _reProcPath.Truncate(); e != nil {
		h.ws.HttpError(c, 500, e.Error(), e)
	} else {
		res := map[string]interface{}{"removed": n}
		c.JSON(200, res)
	}
}

func (h *ApiHandler) ReProcessStats(c *gin.Context) {
	if stats, e := _reProc.GetStats(); e != nil {
		h.ws.HttpError(c, 500, "ReProcessStats", e)
	} else {
		stats.PathQueue = int(_reProcPath.Size())
		c.JSON(200, stats)
	}
}

func (h *ApiHandler) ReProcessStatsRemove(c *gin.Context) {
	if e := _reProc.ClearStats(); e != nil {
		h.ws.HttpError(c, 500, "ReProcessStatsRemove", e)
	} else {
		c.JSON(204, nil)
	}
}

func (h *ApiHandler) RecoverQueueCount(c *gin.Context) {
	if _recover == nil {
		h.ws.HttpError(c, 503, "bulkRecovery unavailable", nil)
	} else if res, e := _recover.Stats(); e != nil && res.Sum == 0 {
		h.ws.HttpError(c, 500, e.Error(), e)
	} else {
		c.JSON(200, res)
	}
}

func (h *ApiHandler) RecoverQueueTruncate(c *gin.Context) {
	var (
		dts   = c.Query("after")
		dt, _ = time.ParseInLocation("2006-01-02T15:04:05", dts, time.UTC)
	)
	if dt.Year() < 2000 {
		h.ws.HttpError(c, 400, fmt.Sprintf("Invalid or missing 'after' date value: %v", dt), nil)
	} else if _recover == nil {
		h.ws.HttpError(c, 503, "bulkRecovery unavailable", nil)
	} else if res, e := _recover.Truncate(dt); e != nil && res.Sum == 0 {
		h.ws.HttpError(c, 500, e.Error(), e)
	} else {
		c.JSON(200, res)
	}
}

func (h ApiHandler) explodePaths(matches []*s3Prefix) [][]string {
	var (
		matchUrls   = make([]string, 0)
		matchLen    = 0
		matchBatch  = 64
		envBatchStr = getEnvOrDefault("FLO_PATH_QUEUE_BATCH", "")
	)
	paths := make([][]string, 0)
	if n, _ := strconv.ParseInt(envBatchStr, 10, 64); n >= 10 {
		matchBatch = int(n)
	}
	for _, m := range matches {
		for _, pre := range m.Expand() {
			if url := pre.PrefixPath(); url != "" {
				matchUrls = append(matchUrls, url)
				matchLen++
				if matchLen%matchBatch == 0 {
					paths = append(paths, matchUrls)
					matchUrls = make([]string, 0)
				}
			}
		}
	}
	if len(matchUrls) != 0 {
		paths = append(paths, matchUrls)
	}
	return paths
}
