package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/pkg/errors"

	"github.com/go-redis/redis/v8"
)

type EnsureFwSync interface {
	Open()
	Close()
}

const (
	ENV_SYNC_FW_WORKER_OFF = "DS_SYNC_FW_WORKER_OFF"
	ENV_SYNC_FW_MIN_KEYS   = "DS_SYNC_FW_MIN_KEYS"
)

func CreateEnsureSync(redis *redis.ClusterClient, pg *sql.DB, recon EnsureReconciliation, audit ReconAudit) EnsureFwSync {
	ensure := ensureFwSync{
		redis:     redis,
		pg:        pg,
		recon:     recon,
		audit:     audit,
		fwMinKeys: 16, //default min fw keys
		isDebug:   strings.EqualFold(Env, "local"),
		isOff:     strings.EqualFold(getEnvOrDefault(ENV_SYNC_FW_WORKER_OFF, ""), "true"),
	}
	logNotice("%s=%v", ENV_SYNC_FW_WORKER_OFF, ensure.isOff)
	if n, _ := strconv.Atoi(getEnvOrDefault(ENV_SYNC_FW_MIN_KEYS, "")); n > 0 {
		ensure.fwMinKeys = int32(n)
	}
	logInfo("%s==%v", ENV_SYNC_FW_MIN_KEYS, ensure.fwMinKeys)
	return &ensure
}

// worker & logic that ensure devices that required sync, are synced at least once a day
type ensureFwSync struct {
	redis     *redis.ClusterClient
	pg        *sql.DB
	recon     EnsureReconciliation
	audit     ReconAudit
	today     int64 //current day in unix time
	fwMinKeys int32
	state     int32 //0=closed,1=open
	isDebug   bool
	isOff     bool
}

type verRank struct {
	version string
	count   int32
}

// get common max version number
func (w *ensureFwSync) getFwVerMax() (string, error) {
	var (
		res   *fwRes
		e     error
		tries = []time.Duration{time.Minute, time.Minute * 5, time.Hour, time.Hour * 4, DUR_1_DAY}
	)
	for _, sampleDur := range tries {
		if res, e = w.getFwVers(sampleDur); e != nil {
			logError("getFwVerMax: getFwVers %v failed | %v", sampleDur, e)
			return "", e
		} else if res.rows > 2 && len(res.vMap) >= 2 {
			break //use as is
		}
	}
	if res.rows == 0 {
		logError("can't find version info")
		return "", errors.New("getFwVerMax: can't find version info")
	}

	var (
		max   string //abs max
		sum   int32  //sum of all occurrences
		ranks = make([]*verRank, 0, len(res.vMap))
	)
	for v, count := range res.vMap {
		sum += count
		if w.versionCompare(v, max) > 0 {
			max = v
		}
		ranks = append(ranks, &verRank{v, count})
	}
	sort.Slice(ranks, func(i, j int) bool {
		return ranks[i].count > ranks[j].count
	})
	if majority := float32(ranks[0].count) / float32(sum); majority >= 0.7 { //70% majority
		logInfo("getFwVerMax: found %v", ranks[0].version)
		return ranks[0].version, nil
	}
	logInfo("getFwVerMax: found %v", max)
	return max, nil //no stable majority, return abs max
}

// parse version into major minor int32
func (w *ensureFwSync) version(x string) (major, minor int32) {
	arr := strings.Split(x, ".")
	if al := len(arr); al > 0 { //has major
		if n, _ := strconv.ParseInt(arr[0], 10, 32); n > 0 {
			major = int32(n)
			if al > 1 { //has minor
				if n, _ = strconv.ParseInt(arr[1], 10, 32); n > 0 {
					minor = int32(n)
				}
			}
		}
	}
	return
}

// compare x & y version, if x > y, return 1 else if x == y, return 0 else return -1
func (w *ensureFwSync) versionCompare(x, y string) int32 {
	var (
		xMajor, xMinor = w.version(x)
		yMajor, yMinor = w.version(y)
	)
	if xMajor == yMajor {
		if xMinor == yMinor {
			return 0
		} else if xMinor > yMinor {
			return 1
		} else {
			return -1
		}
	} else if xMajor > yMajor {
		return 1
	} else {
		return -1
	}
}

type fwRes struct {
	vMap map[string]int32
	rows int32
}

// get a list of version samples in the last X minutes
func (w *ensureFwSync) getFwVers(sampleDur time.Duration) (*fwRes, error) {
	started := time.Now()
	const query = `select fw_ver from devices where last_heard_from_time >= $1 AND is_connected=true AND model like 'flo_device%';`
	if rows, e := w.pg.Query(query, time.Now().UTC().Add(-sampleDur)); e != nil {
		logError("getFwVers: query %v | %v", sampleDur, e)
		return nil, e
	} else {
		defer rows.Close()
		var (
			res          = fwRes{vMap: make(map[string]int32)}
			major, minor int32
		)
		for rows.Next() {
			res.rows++
			var vs sql.NullString
			if e = rows.Scan(&vs); e != nil {
				logWarn("getFwVers: scan %v | %v", sampleDur, e)
				continue
			}
			if !vs.Valid {
				continue
			}
			if major, minor = w.version(vs.String); major > 0 {
				v := fmt.Sprintf("%v.%v", major, minor) //discard patch
				if count, ok := res.vMap[v]; ok {
					res.vMap[v] = count + 1
				} else {
					res.vMap[v] = 1
				}
			}
		}
		logDebug("getFwVers: %v fetched %v, found %v | took %vms", sampleDur, res.rows, len(res.vMap), time.Since(started).Milliseconds())
		return &res, nil
	}
}

type fwVer struct {
	mac   string //device mac-address
	ver   string //fw version
	jKeys int32  //json key count
}

func (w *ensureFwSync) syncOldFw(ctx context.Context) {
	defer panicRecover("syncOldFw")

	logNotice("syncOldFw: Started")
	var (
		started   = time.Now()
		maxVer, _ = w.getFwVerMax()
	)
	if major, _ := w.version(maxVer); major == 0 {
		logFatal("syncOldFw: can not determine max fw version!")
		return
	}

	var (
		mac     string //blank starting cursor
		res     syncFwBatchRes
		ok      = true
		fetched int32
		synced  int32
	)
	for ok {
		res = w.fwSyncBatch(mac, maxVer)
		fetched += res.Fetched
		if ok = res.LastMac != "" && res.Fetched > 0; ok { //will stop when result is empty
			mac = res.LastMac //starting cursor
		}
		for _, fw := range res.Items {
			if w.recon.SyncDevice(ctx, fw.mac, "EnsureFwSync", true) {
				synced++
			}
		}
	}
	logNotice("syncOldFw: Completed. fetched=%v synced=%v took=%v", fetched, synced, time.Since(started))
}

type syncFwBatchRes struct {
	Items   []fwVer `json:"items"`
	LastMac string  `json:"lastMac"`
	Fetched int32   `json:"fetched"`
}

func (sr syncFwBatchRes) String() string {
	return fmt.Sprintf("items=%v,last=%s,fetched=%v", len(sr.Items), sr.LastMac, sr.Fetched)
}

type JsonMap map[string]interface{}

func (a JsonMap) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *JsonMap) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &a)
}

func (w *ensureFwSync) fwSyncBatch(macStart, maxVer string) syncFwBatchRes {
	defer panicRecover("fwSyncBatch: %s", macStart)
	const query = `select device_id,fw_ver,fw_properties_raw from devices 
		where device_id > $1 and last_heard_from_time > $2 and 
  			fw_ver is not null and fw_properties_raw is not null and model like 'flo_device_%' and is_connected=true 
		order by device_id asc limit $3;` //paginated by batch
	var (
		started  = time.Now()
		dayStart = time.Now().UTC().Truncate(DUR_1_DAY)
		limit    = 200
		res      = syncFwBatchRes{Items: make([]fwVer, 0)}
		rows, e  = w.pg.Query(query, macStart, dayStart, limit)
	)
	if e != nil {
		logError("fwSyncBatch: query %s | %v", macStart, e)
		return res
	}

	defer rows.Close()
	for rows.Next() {
		res.Fetched++
		var (
			d      = fwVer{}
			fwProp = JsonMap{}
		)
		if e = rows.Scan(&d.mac, &d.ver, &fwProp); e != nil {
			logWarn("fwSyncBatch: scan | %v", e)
			continue
		}
		d.mac = strings.ToLower(d.mac)
		res.LastMac = d.mac
		if isSwsV1(d.mac) {
			continue
		}
		d.jKeys = w.countKeys(fwProp)
		if d.jKeys <= w.fwMinKeys || w.versionCompare(d.ver, maxVer) < 0 { //older version
			res.Items = append(res.Items, d)
		}
	}
	logInfo("fwSyncBatch: macStart=%s took %vms | %v", macStart, time.Since(started).Milliseconds(), res)
	return res
}

func (w *ensureFwSync) countKeys(vm map[string]interface{}) int32 {
	sum := int32(len(vm))
	if sum > 0 {
		for _, v := range vm {
			if cm, ok := v.(map[string]interface{}); ok {
				sum += w.countKeys(cm)
			}
		}
	}
	return sum
}

func (w *ensureFwSync) Open() {
	defer panicRecover("EnsureFwSync.Opening")
	ctx := context.Background()
	if w != nil && !w.isOff && atomic.CompareAndSwapInt32(&w.state, 0, 1) {
		time.Sleep(time.Second * 10)

		logNotice("EnsureFwSync.Opening")
		exp := DUR_1_DAY
		if w.isDebug {
			exp = time.Minute * 5
		}

		go w.rmOldAuditLogs(ctx)
		for atomic.LoadInt32(&w.state) == 1 {
			var (
				k   = fmt.Sprintf("syncOldFw_%s:{%s}", Env, time.Now().UTC().Format("06-01-02"))
				cmd = w.redis.SetNX(ctx, k, _hostname, exp)
			)
			if ok, e := cmd.Result(); e != nil && e != redis.Nil {
				logError("EnsureFwSync: lock failed %s", k)
			} else if ok {
				w.syncOldFw(ctx)
			} else {
				logDebug("EnsureFwSync: already synced")
			}
			time.Sleep(time.Hour * 2)
		}
	}
}

func (w *ensureFwSync) rmOldAuditLogs(ctx context.Context) {
	defer panicRecover("rmOldAuditLogs")
	var (
		sd = time.Minute * 5
		rm = time.Now().UTC().Truncate(DUR_1_DAY).Add(DUR_1_DAY * -92)
		k  = fmt.Sprintf("recon:audit:clean:{%s}", rm.Format("2006-01-02"))
	)
	if w.isDebug {
		sd = time.Second * 10
	}
	time.Sleep(sd)
	cmd := w.redis.SetNX(ctx, k, _hostname, DUR_1_DAY) //run once a day only
	if ok, e := cmd.Result(); e != nil && e != redis.Nil {
		logError("rmOldAuditLogs: %s | %v", k, e)
	} else if ok {
		w.audit.RemoveBefore(rm)
	}
}

func (w *ensureFwSync) Close() {
	if w != nil && atomic.CompareAndSwapInt32(&w.state, 1, 0) {
		logNotice("EnsureFwSync.Closing")
	}
}
