package main

import (
	"fmt"
	"sort"
	"time"
)

const DEPLOY_RETRY_SECONDS int = 3600
const VERIFY_DEPLOYMENT int = 900

func initFloSenseRetryWorker() {
	go floSenseHouseKeepingWorker()
	go floSenseModelVerification()
}

func floSenseModelVerification() {
	retryTime := time.Duration(VERIFY_DEPLOYMENT) * time.Second
	nextRun := time.Now().UTC().Add(time.Minute)

	logNotice("floSenseModelVerification: Start - run every %v seconds, next run at %v",
		VERIFY_DEPLOYMENT, nextRun.Format(time.RFC3339))

	for {
		if time.Now().UTC().Before(nextRun) {
			time.Sleep(time.Second)
			continue
		}

		nextRun = time.Now().UTC().Truncate(retryTime).Add(retryTime)
		start := time.Now()
		items := tryGetReadyModels()
		if len(items) == 0 {
			continue
		}

		logDebug("floSenseModelVerification: Starting to verify %v devices", len(items))
		count := 0

		for _, i := range items {

			// Protect from bombarding the device
			key := fmt.Sprint("mutex:flosense:verify:%v", i.MacAddress)
			result, err := _redis.SetNX(key, tryToJson(i), 300)
			if err != nil {
				logError("floSenseModelVerification: redis error. %v %v", i.MacAddress, err.Error())
				continue
			}
			if !result {
				// There has already been an attempt to verify in the last 300 seconds, wait for next retry
				continue
			}

			count++
			dsSyncDevice(i.MacAddress)
		}

		logDebug("floSenseModelVerification: Took %.3f seconds for %v/%v, next run at %v",
			time.Now().Sub(start).Seconds(), count, len(items), nextRun.Format(time.RFC3339))
	}
}

func floSenseHouseKeepingWorker() {
	retryTime := time.Duration(DEPLOY_RETRY_SECONDS) * time.Second
	nextRun := time.Now().UTC().Truncate(retryTime).Add(retryTime)

	logNotice("floSenseHouseKeepingWorker: Start - run every %v seconds, next run at %v",
		DEPLOY_RETRY_SECONDS, nextRun.Format(time.RFC3339))

	for {
		if time.Now().UTC().Before(nextRun) {
			time.Sleep(time.Second)
			continue
		}

		nextRun = time.Now().UTC().Truncate(retryTime).Add(retryTime)

		start := time.Now()
		floSenseDoCleanup()
		logDebug("floSenseHouseKeepingWorker: Took %.3f seconds, next run at %v",
			time.Now().Sub(start).Seconds(), nextRun.Format(time.RFC3339))
	}
}

func floSenseDoCleanup() {
	cleanupErrorModels()
	expireOldModels()
	retryReadyModels()
	auditFloSenseLevels()
}

func cleanupErrorModels() {
	_, err := _pgCn.ExecNonQuery("DELETE FROM flosense_models WHERE state < 0 AND updated<$1", time.Now().UTC().Add(-744*time.Hour))
	if err != nil {
		logError("cleanupErrorModels: delete old errors. %v", err.Error())
	}
}

func expireOldModels() {
	_, err := _pgCn.ExecNonQuery("UPDATE flosense_models SET state=$1,updated=$2 WHERE state>=0 AND state<100 AND expire<$2",
		MODEL_STATUS_EXPIRED,
		time.Now().UTC().Truncate(time.Second))
	if err != nil {
		logError("expireOldModels: expire old records. %v", err.Error())
	}
}

func retryReadyModels() {
	items := tryGetReadyModels()
	if len(items) == 0 {
		return
	}

	for _, i := range items {
		if len(i.DownloadLocation) == 0 {
			continue
		}
		sendInitialPropertiesToDevice(i)
	}
}

func tryGetReadyModels() []*FloSenseApiModel {
	rows, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
		" FROM flosense_models "+
		" WHERE state=$1 AND expire>$2;",
		MODEL_STATUS_READY,
		time.Now().UTC())

	if e != nil {
		logError("floSenseRetryWorker: db error. %v", e.Error())
		return nil
	}
	defer rows.Close()

	rv := make([]*FloSenseApiModel, 0)
	for rows.Next() {
		delta := parseModelDbRecord(rows)
		rv = append(rv, delta)
	}

	if len(rv) > 0 {
		sort.Slice(rv, func(a int, b int) bool { return rv[a].MacAddress < rv[b].MacAddress })
	}

	return rv
}

func auditFloSenseLevels() {
	rows, e := _pgCn.Query("select device_id, device_level from flosense where device_level != device_level_last;")

	if e != nil {
		logError("auditFloSenseLevels: db error. %v", e.Error())
		return
	}
	defer rows.Close()

	rv := make([]*LevelAudit, 0)
	for rows.Next() {

		delta := new(LevelAudit)
		rows.Scan(&delta.MacAddress, &delta.ShutoffLevel)

		if isValidMacAddress(delta.MacAddress) {
			rv = append(rv, delta)
		}
	}

	if len(rv) > 0 {
		sort.Slice(rv, func(a int, b int) bool { return rv[a].MacAddress < rv[b].MacAddress })
	}

	for _, i := range rv {
		// Protect from bombarding the device
		key := fmt.Sprint("mutex:flosense:shutoffaudit:%v", i.MacAddress)
		result, _ := _redis.SetNX(key, tryToJson(i), 30*60)
		if !result {
			continue
		}

		sendFwProperties(i.MacAddress, i.ShutoffLevel)
	}
}

type LevelAudit struct {
	MacAddress   string
	ShutoffLevel int
}
