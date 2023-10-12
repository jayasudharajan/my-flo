package main

import (
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

const (
	ENVVAR_TIMESCALE_DB_CN         = "FLO_TIMESCALE_DB_CN"
	ENVVAR_TIMESCALE_WRITE_BATCH   = "FLO_TIMESCALE_WRITE_BATCH"
	ENVVAR_TIMESCALE_WRITE_THREADS = "FLO_TIMESCALE_WRITE_THREADS"
	DEFAULT_TIMESCALE_WRITE_BATCH  = 1 // WARNING: batch > 2 WILL cause high CPU on TSDB
	DEFAULT_DYNAMO_WRITE_BATCH     = 22
)

// WaterWriter interface to insert, update, delete TSDB data
type WaterWriter interface {
	Open() error
	IsOpen() bool
	Close()
	Write(batch []*AggregateTelemetry) error
	Remove(rm *RemoveDataReq) (int, error)
	DropHourlyAggregates(time.Time) (int, error)
	RefreshHourlyAggregates(from, to time.Time) error

	MoveToArchive(WaterArchiveData, string) error
	EditAttribute(string) (*WaterMeterAttribute, error)
	UpdateAttribute(*WaterMeterAttribute) error
}

func CreateArchiveWaterWriter() WaterWriter {
	tsConn := getEnvOrDefault(ENVVAR_TIMESCALE_DB_CN, "")

	w := CreateWaterWriter(tsConn, _log)
	return w
}

func CreateWaterWriter(tsConn string, log *Logger) WaterWriter {
	return &waterWriter{tsCn: tsConn, log: log.CloneAsChild("TsWrite")}
}

type waterWriter struct {
	ts       *PgSqlDb
	dynamodb *dynamoDBSession
	tsCn     string // TimeScaleDB connection string
	state    int32  // 0 == unknown, 1 == running, 2 == stopped
	log      *Logger
}

func (c *waterWriter) MustOpen() *waterWriter {
	if c != nil {
		if e := c.Open(); e != nil {
			os.Exit(10)
		}
	}
	return c
}

func (c *waterWriter) IsOpen() bool {
	return c != nil && atomic.LoadInt32(&c.state) == 1
}

func (c *waterWriter) Open() error {
	if c == nil {
		return errors.New("waterWriter.Open: binder nil ref")
	}
	if atomic.CompareAndSwapInt32(&c.state, 0, 1) {
		if c.tsCn == "" {
			return c.log.Error("Open: connection string is empty")
		}
		var e error
		if c.ts, e = OpenPgSqlDb(c.tsCn); e != nil {
			return e
		}
		if c.dynamodb, e = DynamoSingleton(); e != nil {
			return e
		}
		c.log.Info("Open: OK")
	}
	return nil
}

func (c *waterWriter) EditAttribute(key string) (*WaterMeterAttribute, error) {
	attr := WaterMeterAttribute{}
	rows, err := c.ts.Connection.Query("select attr_id, attr_val, updated_at from water_meter_attr where attr_id = $1 limit 1", key)
	if err != nil {
		return nil, logWarn("WaterWriter: EditAttribute query failed, %v", err.Error())
	}
	defer rows.Close()
	for rows.Next() {
		err = rows.Scan(&attr.ID, &attr.Value, &attr.UpdatedAt)
		if err != nil {
			return nil, logWarn("WaterWriter: EditAttribute scan failed, %v", err.Error())
		}
	}
	return &attr, nil
}

func (c *waterWriter) UpdateAttribute(attribute *WaterMeterAttribute) error {
	_, err := c.ts.ExecNonQuery("UPDATE water_meter_attr set attr_val = $1, updated_at = $2 where attr_id = $3",
		attribute.Value, time.Now().UTC(), attribute.ID)
	if err != nil {
		return logWarn("WaterWriter: UpdateAttribute failed, %v", err.Error())
	}

	return nil
}

func (c *waterWriter) DropHourlyAggregates(endDate time.Time) (int, error) {
	query := fmt.Sprintf("SELECT drop_chunks('water_hourly', older_than => DATE '%s')", endDate.UTC().Truncate(24*time.Hour).Format("2006-01-02"))
	rows, err := c.ts.Connection.Query(query)
	if err != nil {
		return 0, logWarn("WaterWriter: DropAggregates query failed %s, %v", query, err.Error())
	}
	defer rows.Close()
	count := 0
	for rows.Next() {
		count++
	}
	return count, nil
}

func (w *waterWriter) RefreshHourlyAggregates(from, to time.Time) error {
	const stmt = "CALL refresh_continuous_aggregate('water_hourly','%v','%v');"
	var (
		frmDt   = from.UTC().Format(FMT_RED_MAP_LASTDT)
		toDt    = to.UTC().Format(FMT_RED_MAP_LASTDT)
		sqlStmt = fmt.Sprintf(stmt, frmDt, toDt)
	)
	if _, e := w.ts.ExecNonQuery(sqlStmt); e != nil {
		w.log.IfErrorF(e, "RefreshHourlyAggregates: %v -> %v", from.Format(FMT_RED_MAP_LASTDT), to.Format(FMT_RED_MAP_LASTDT))
		return e
	}
	return nil
}

func (c *waterWriter) MoveToArchive(wad WaterArchiveData, source string) error {
	items := make([]interface{}, 0)
	for did, wds := range wad {

		for _, wd := range wds {
			record := WaterArchiveDocumentRecord{
				DeviceID:    did,
				TimeBucket:  wd.Bucket,
				UpdatedAt:   time.Now().UTC(),
				Consumption: wd.Consumption,
				FlowRate:    wd.Avg.FlowRate,
				Pressure:    wd.Avg.Pressure,
				Temp:        wd.Avg.Temp,
				Seconds:     wd.Seconds,
				FlowSeconds: wd.FlowSeconds,
				Source:      source,
			}
			if wd.Min != nil {
				record.Min = &WaterArchiveFuncRecord{
					FlowRate: wd.Min.FlowRate,
					Pressure: wd.Min.Pressure,
					Temp:     wd.Min.Temp,
				}
			}
			if wd.Max != nil {
				record.Max = &WaterArchiveFuncRecord{
					FlowRate: wd.Max.FlowRate,
					Pressure: wd.Max.Pressure,
					Temp:     wd.Max.Temp,
				}
			}
			items = append(items, record)
			if len(items) == DEFAULT_DYNAMO_WRITE_BATCH {
				err := c.dynamodb.BatchUpdate(ARCHIVE_TABLE_NAME, items...)
				if err != nil {
					_log.Error("MoveToArchiveBatchFailed %v", err)
				}
				items = make([]interface{}, 0)
			}
		}
	}

	if len(items) > 0 {
		err := c.dynamodb.BatchUpdate(ARCHIVE_TABLE_NAME, items...)
		if err != nil {
			_log.Error("MoveToArchiveBatchFailed %v", err)
		}
	}

	return nil
}

func (c *waterWriter) Close() {
	if c != nil && c.ts != nil && atomic.CompareAndSwapInt32(&c.state, 1, 0) {
		c.ts.Close()
		c.ts = nil
		c.log.Info("Close: OK")
	}
}

// AggregateTelemetry Stores the 5min aggregated telemetry data
type AggregateTelemetry struct {
	DeviceId   string `json:"did"`        //mac address
	TimeBucket int64  `json:"timeBucket"` //when the time bucket starts in unix epoch MS
	Seconds    int32  `json:"seconds"`    //how many seconds are rolled up into this aggregate
	SecondsFlo int32  `json:"secondsFlo"` //how many seconds with flowing water in this bucket

	// When bytes are full, empty strings are returned instead to save space.
	// byte array of 300 (seconds) bit mask: 300 bits / 8 = ~38 (rounded up) slots.
	SecondsFill []byte `json:"secondsFill"`

	UseGallons float32 `json:"useGallons"` //total water usage by gallon

	GpmSum    float32 `json:"gpmSum"` //gallon per minute sum
	GpmMinFlo float32 `json:"gpmMin"` //minimum gpm while water is flowing
	GpmMax    float32 `json:"gpmMax"` //gpm max

	PsiSum float32 `json:"psiSum"` //psi sumf
	PsiMin float32 `json:"psiMin"` //psi min
	PsiMax float32 `json:"psiMax"` //psi max

	TempSum float32 `json:"tempSum"` //temperature sum
	TempMin float32 `json:"tempMin"` //temperature min
	TempMax float32 `json:"tempMax"` //temperature max
}

func (a AggregateTelemetry) String() string {
	return fmt.Sprintf("%s %s", a.DeviceId, time.Unix(a.TimeBucket/1000, 0).Format("060102T1504"))
}

func (c *waterWriter) Write(batch []*AggregateTelemetry) error {
	defer recoverPanic(c.log, "Write: %p", batch)
	var (
		inserts, upserts = c.batchSeparateKinds(batch)
		es               = make([]error, 0)
	)
	if len(inserts) > 0 { //inserts are combined and sent as a batch (1 statement)
		if fr, e := c.flushAggregate(inserts...); e != nil {
			es = append(es, e)
		} else {
			c.log.Info(fr.Info(inserts...))
		}
	}
	for _, u := range upserts { //upsert are run as individual statements
		if fr, e := c.flushAggregate(u); e != nil {
			es = append(es, e)
		} else {
			c.log.Info(fr.Info(u))
		}
	}
	return wrapErrors(es)
}

func (c *waterWriter) batchSeparateKinds(batch []*AggregateTelemetry) (inserts, upserts []*AggregateTelemetry) {
	size := len(batch)
	inserts = make([]*AggregateTelemetry, 0)
	upserts = make([]*AggregateTelemetry, 0)
	if size > 0 {
		for _, v := range batch { //separates into 2 buckets
			if v.Seconds < MAX_FILL_BITS {
				upserts = append(upserts, v)
			} else {
				inserts = append(inserts, v)
			}
		}
	}
	return inserts, upserts
}

// takes a collection of telemetry pointers & return array of parameter row (each one is an array/column of any type)
func (c *waterWriter) flushAggregate(batch ...*AggregateTelemetry) (tsFlushResult, error) {
	var (
		startDt = time.Now()
		r       = tsFlushResult{Received: int64(len(batch))}
	)
	if r.Received > 0 {
		sqlStr := c.buildWriteQuery(batch...)
		statements := strings.Count(sqlStr, ";")
		if statements < 1 {
			statements = 1
		}
		if c.log.isDebug && _noWrite { //safe prod test
			return r, nil
		}
		sr, err := c.ts.ExecNonQuery(sqlStr) //flush batch
		if err != nil {
			c.log.Error("flushAggregate: execute => %v", err.Error())
			return r, err
		} else {
			for i := 0; i < statements; i++ {
				if w, e := sr.RowsAffected(); e != nil {
					c.log.Warn("flushAggregate: read response => %v", e.Error())
				} else {
					r.Written += w
				}
			}
		}
		sr = nil
	}
	r.Took = time.Since(startDt)
	return r, nil
}

// sql upsert template matching schema @ ../ts/hybrid.sql
// the goal of the bit mask operations in the update where clause is:
// 1: to convert to a bit string of all 0's
// 2: if not all 0's are returned, reject the entire update
const _insertHead = `

INSERT INTO water_5min AS w (
	bk, device_id,
	seconds, seconds_flo, seconds_slot,
	total_gallon,
	gpm_sum, gpm_min_flo, gpm_max,
	psi_sum, psi_min, psi_max,
	temp_sum, temp_min, temp_max 
) VALUES `

const _insertFoot = `
 ON CONFLICT (device_id,bk) DO NOTHING;
`

const _upsertFoot = `
 ON CONFLICT (device_id,bk) DO UPDATE SET 
	seconds = w.seconds + EXCLUDED.seconds,
	seconds_flo = w.seconds_flo + EXCLUDED.seconds_flo,
	seconds_slot = w.seconds_slot | EXCLUDED.seconds_slot,

	total_gallon = w.total_gallon + EXCLUDED.total_gallon,

	gpm_sum = w.gpm_sum + EXCLUDED.gpm_sum,
	gpm_min_flo = w.gpm_min_flo + EXCLUDED.gpm_min_flo,
	gpm_max = w.gpm_max + EXCLUDED.gpm_max,

	psi_sum = w.psi_sum + EXCLUDED.psi_sum,
	psi_min = w.psi_min + EXCLUDED.psi_min,
	psi_max = w.psi_max + EXCLUDED.psi_max,

	temp_sum = w.temp_sum + EXCLUDED.temp_sum,
	temp_min = w.temp_min + EXCLUDED.temp_min,
	temp_max = w.temp_max + EXCLUDED.temp_max
WHERE 
	w.bk = EXCLUDED.bk AND 
	w.device_id = EXCLUDED.device_id AND 
	w.seconds_slot | ~EXCLUDED.seconds_slot & EXCLUDED.seconds_slot = 0::BIT(300);`

func (c *waterWriter) buildWriteQuery(batch ...*AggregateTelemetry) string {
	sb := c.log.sbPool.Get()
	defer c.log.sbPool.Put(sb)

	lastUpsert := false
	for i := 0; i < len(batch); i++ {
		a := batch[i]
		isUpsert := a.Seconds < MAX_FILL_BITS
		bucket := time.Unix(a.TimeBucket/1000, 0).Format("2006-01-02 15:04:05.000") // preserve ms precision
		fill := pgConvByteArrToBitStr(a.SecondsFill)

		if i == 0 || isUpsert || (!isUpsert && lastUpsert) {
			if i > 0 && !lastUpsert {
				sb.WriteString(_insertFoot)
			}
			sb.WriteString(_insertHead)
		} else if !lastUpsert && !isUpsert {
			sb.WriteString(",")
		}
		sb.WriteString(fmt.Sprintf(`(
		'%v', '%v',
		%v, %v, B'%v',
		%v,
		%v, %v, %v,
		%v, %v, %v,
		%v, %v, %v
)`,
			bucket, a.DeviceId,
			a.Seconds, a.SecondsFlo, fill,
			a.UseGallons,
			a.GpmSum, a.GpmMinFlo, a.GpmMax,
			a.PsiSum, a.PsiMin, a.PsiMax,
			a.TempSum, a.TempMin, a.TempMax))
		if isUpsert {
			sb.WriteString(_upsertFoot)
		}
		lastUpsert = isUpsert
	}
	if !lastUpsert {
		sb.WriteString(_insertFoot)
	}
	return sb.String()
}

// timescale db flush result.
type tsFlushResult struct {
	Received int64
	Written  int64
	Took     time.Duration
}

func (f *tsFlushResult) Info(batch ...*AggregateTelemetry) string {
	if f == nil {
		return ""
	}
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	sb.WriteString(fmt.Sprintf(" %vms [%v %v] ", float32(f.Took.Microseconds())/1000, f.Received, f.Written))
	for _, a := range batch {
		sb.WriteString(a.String())

		filled := base64.StdEncoding.EncodeToString(a.SecondsFill)
		if filled == "" {
			filled = "_full_"
		}
		sb.WriteString(" ")
		sb.WriteString(filled)
		sb.WriteString(":")
		sb.WriteString(strconv.Itoa(int(a.SecondsFlo)))
		sb.WriteString(" | ")
	}
	return sb.String()
}

func (w *waterWriter) Remove(rm *RemoveDataReq) (int, error) {
	if w == nil {
		return 0, errors.New("waterWriter.Remove: binding nil ref")
	}
	if rm == nil {
		return 0, w.log.Warn("Remove: rm is nil")
	}
	cxArr := rm.buildSqlContext()
	var n int
	for _, cx := range cxArr {
		if rm.DryRun {
			if cx.updateRow > 0 {
				diff := rm.EndDate.Sub(rm.StartDate).Minutes() / 5
				n = int(diff)
			}
			w.log.Info("RemoveData: %v dryRun | %v -> %v", rm.MacAddr, cx.sb.String(), cx.args)
		} else if sr, e := w.ts.ExecNonQuery(cx.sb.String(), cx.args...); e != nil {
			w.log.IfWarnF(e, "RemoveData: %v", rm)
			return 0, e
		} else if cx.updateRow > 0 {
			for i := 0; i < cx.updateRow; i++ {
				if rowCount, err := sr.RowsAffected(); err == nil {
					n += int(rowCount)
					if i == cx.updateRow-1 {
						break
					}
				}
			}
			continue
		}
	}
	if !rm.DryRun {
		w.log.Info("RemoveData: %v rows OK %v | %v -> %v", n, rm.MacAddr, rm.StartDate, rm.EndDate)
	}
	return n, nil
}

type rmSqlCx struct {
	sb        strings.Builder
	args      []interface{}
	updateRow int
}

func (rq *RemoveDataReq) buildSqlContext() []*rmSqlCx {
	var (
		cx1 = rmSqlCx{sb: strings.Builder{}, args: make([]interface{}, 0, 3), updateRow: 1}
		res = append(make([]*rmSqlCx, 0, 2), &cx1)
	)
	cx1.sb.WriteString("delete from water_5min where device_id=$1 ")
	cx1.args = append(cx1.args, rq.MacAddr)
	if rq.StartDate.Year() > 2000 {
		cx1.sb.WriteString(" and bk >= $2 ")
		cx1.args = append(cx1.args, rq.StartDate.Truncate(DUR_1_DAY))
	}
	if rq.EndDate.Year() > 2000 {
		cx1.sb.WriteString(" and bk < $3 ")
		cx1.args = append(cx1.args, rq.EndDate.Truncate(DUR_1_DAY))
	}
	cx1.sb.WriteString("; ")
	if rq.ReCompute {
		cx2 := rmSqlCx{sb: strings.Builder{}, args: make([]interface{}, 0)}
		cx2.sb.WriteString("REFRESH MATERIALIZED VIEW water_hourly; ")
		res = append(res, &cx2)
	}
	return res
}
