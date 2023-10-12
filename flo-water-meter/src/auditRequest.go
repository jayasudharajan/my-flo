package main

import (
	"net/http"
	"time"
)

func auditRequest(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	model := DeviceDateRequest{}
	httpReadBody(w, r, &model)

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

	// Process out of sync - this may take a long time
	if model.AuditYear {
		go func(m DeviceDateRequest) {
			defer recoverPanic(_log, "auditRequest year async | %v", tryToJson(m))
			fm := tsWaterReader.GetDeviceFirstDataCached(model.Blocking, m.MacAddress)
			dt, _ := fm[m.MacAddress]
			auditDeviceLongTermCache(dt, m.MacAddress, "api.audit", m.Force)
		}(model)
	} else {
		go func(m DeviceDateRequest) {
			defer recoverPanic(_log, "auditRequest async | %v", tryToJson(m))
			auditDeviceCache(m.MacAddress, m.realFrom, m.realTo, "api.audit", m.Force)
		}(model)
	}

	httpWrite(w, 202, model, started)
}
