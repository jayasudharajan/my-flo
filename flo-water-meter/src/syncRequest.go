package main

import (
	"net/http"
	"sync/atomic"
	"time"
)

type DeviceDateRequest struct {
	MacAddress string `json:"macAddress"`
	StartDate  string `json:"startDate"`
	EndDate    string `json:"endDate"`
	Force      bool   `json:"force,omitempty"`
	AuditYear  bool   `json:"auditYear,omitempty"`
	Blocking   bool   `json:"blocking,omitempty"`
	realFrom   time.Time
	realTo     time.Time
}

//doesn't try to repair like audit, just force sync
func syncRequest(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	model := DeviceDateRequest{}
	if e := httpReadBody(w, r, &model); e != nil {
		return
	}
	if len(model.MacAddress) != 12 {
		httpError(w, 400, "macAddress is invalid", nil)
		return
	}
	model.realFrom = tryParseDate(model.StartDate)
	model.realTo = tryParseDate(model.EndDate)
	if model.realFrom.Year() < 2000 || model.realFrom.Year() > 2100 {
		model.realFrom = time.Now().UTC().Truncate(24 * time.Hour)
	}
	if model.realTo.Year() < 2000 || model.realTo.Year() > 2100 {
		model.realTo = time.Now().UTC().Truncate(24 * time.Hour).Add(24 * time.Hour)
	}
	if model.realTo == model.realFrom {
		model.realTo = model.realFrom.Add(24 * time.Hour)
	}
	if model.realTo.Before(model.realFrom) {
		httpError(w, 400, "endDate must be after startDate", nil)
		return
	}
	model.StartDate = model.realFrom.Format("2006-01-02")
	model.EndDate = model.realTo.Format("2006-01-02")

	if model.Blocking {
		processSyncRequest(model)
		httpWrite(w, 200, model, started)
	} else {
		// Process out of sync - this may take a long time
		go processSyncRequest(model)
		httpWrite(w, 202, model, started)
	}
}

func processSyncRequest(request DeviceDateRequest) {
	json := tryToJson(request)
	ms, _ := mh3Bytes([]byte(json))
	current := request.realFrom
	logDebug("processSyncRequest: %v %v | %v", ms, current, json)
	
	for current.Before(request.realTo) {
		us := current.Format("01-02T15")
		atomic.AddInt64(&_qSize, 1)
		cacheDeviceConsumption(request.MacAddress, current, "api.sync", ms+" "+us)
		current = current.Add(time.Hour * 24)
		backOffHighQueue()
	}
}
