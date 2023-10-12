package main

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis/v8"
)

type EnsureReconciliation interface {
	MarkSynced(ctx context.Context, mac string) bool
	SyncDevice(ctx context.Context, mac, reason string, mqtt bool) bool
	ReconcileAll(macStart string)
}

func CreateEnsureReconciliation(redis *redis.ClusterClient, pg *sql.DB) EnsureReconciliation {
	ensure := ensureRecon{
		redis:   redis,
		pg:      pg,
		isDebug: strings.EqualFold(Env, "local"),
	}
	return &ensure
}

// worker & logic that ensure devices that required sync, are synced at least once a day
type ensureRecon struct {
	redis   *redis.ClusterClient
	pg      *sql.DB
	today   int64 //current day in unix time
	isDebug bool
}

func (w *ensureRecon) MarkSynced(ctx context.Context, mac string) bool {
	defer panicRecover("MarkSynced: %s", mac)
	if w == nil {
		return false
	}
	var (
		today     = time.Now().UTC().Truncate(DUR_1_DAY)
		yesterday = today.Add(-DUR_1_DAY)
		key       = strings.ToLower(fmt.Sprintf("devices:synced:{%s}", today.Format("06-01-02")))
		cmd       = w.redis.SAdd(ctx, key, strings.ToLower(mac))
	)
	if n, e := cmd.Result(); e != nil && e != redis.Nil {
		logError("MarkSynced: %s %s failed | %v", key, mac, e)
	} else if n > 0 { //insert new ok && first run of the day, set TTL
		if atomic.CompareAndSwapInt64(&w.today, 0, today.Unix()) || atomic.CompareAndSwapInt64(&w.today, yesterday.Unix(), today.Unix()) {
			exp := DUR_1_DAY
			if w.isDebug {
				exp = time.Minute * 5
			}
			expCmd := w.redis.ExpireAt(ctx, key, today.Add(exp))
			if e := expCmd.Err(); e != nil && e != redis.Nil { //expires at midnight tomorrow
				logWarn("MarkSynced: %s expire failed | %v", key, e)
			}
		}
		return true
	}
	return false
}

func (w *ensureRecon) SyncDevice(ctx context.Context, mac, reason string, mqtt bool) bool {
	logDebug("SyncDevice: %s", mac)
	var ok bool
	if ok = w.MarkSynced(ctx, mac); ok { //only sync if it hasn't already been done so today
		if ok = verifySystemMode(ctx, mac, reason, false); ok {
			if mqtt {
				go func(addr string) {
					time.Sleep(time.Second * 3) // Send a request for properties after 3 seconds
					PublishToFwPropsMqttTopic(ctx, addr, QOS_1, nil, "get")
				}(mac)
			}
			time.Sleep(time.Millisecond * 100) //throttle a little more
		}
		time.Sleep(time.Millisecond * 5) //throttle a little
	}
	return ok
}

func (w *ensureRecon) ReconcileAll(macStart string) {
	defer panicRecover("ReconcileAll: %q", macStart)
	logNotice("ReconcileAll: %q Started", macStart)
	ctx := context.Background()
	var (
		started = time.Now()
		res     syncAllBatchRes
		ok      = true
		fetched int32
		synced  int32
	)
	for ok {
		res = w.reconBatch(macStart)
		fetched += res.Fetched
		if ok = res.LastMac != "" && res.Fetched > 0; ok { //will stop when result is empty
			macStart = res.LastMac //starting cursor
		}
		for _, mac := range res.Items {
			if w.SyncDevice(ctx, mac, "SyncAll", true) {
				synced++
			}
		}
	}
	logNotice("ReconcileAll: %q Completed. fetched=%v synced=%v took=%v", macStart, fetched, synced, time.Since(started))
}

type syncAllBatchRes struct {
	Items   []string `json:"items"`
	LastMac string   `json:"lastMac"`
	Fetched int32    `json:"fetched"`
}

func (sr syncAllBatchRes) String() string {
	return fmt.Sprintf("items=%v,last=%s,fetched=%v", len(sr.Items), sr.LastMac, sr.Fetched)
}

func (w *ensureRecon) reconBatch(macStart string) syncAllBatchRes {
	defer panicRecover("reconBatch: %s", macStart)
	const query = `select device_id from devices 
		where device_id > $1 and last_heard_from_time > $2 and model like 'flo_device_%' and is_connected=true 
		order by device_id asc limit $3;` //paginated by batch
	var (
		started  = time.Now()
		dayStart = time.Now().UTC().Truncate(DUR_1_DAY * 31)
		limit    = 200
		res      = syncAllBatchRes{Items: make([]string, 0, limit)}
		rows, e  = w.pg.Query(query, macStart, dayStart, limit)
	)
	if e != nil {
		logError("reconBatch: query %s | %v", macStart, e)
		return res
	}

	defer rows.Close()
	for rows.Next() {
		res.Fetched++
		var mac string
		if e = rows.Scan(&mac); e != nil {
			logWarn("reconBatch: scan | %v", e)
			continue
		}
		mac = strings.ToLower(mac)
		res.LastMac = mac
		if len(mac) != 12 || isSwsV1(mac) {
			continue
		}
		res.Items = append(res.Items, mac)
	}
	logInfo("reconBatch: macStart=%s took %vms | %v", macStart, time.Since(started).Milliseconds(), res)
	return res
}
