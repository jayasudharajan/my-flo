package main

import (
	"context"
	"net/http"
	"strings"
	"time"
)

// trendsReportHandler godoc
// @Summary Retrieve FloDetect events for one or more devices based on date range
// @Description Retrieve FloDetect events for one or more devices based on date range. Max of 1000 events per device is returned.
// @Tags Trends
// @Param deviceId query string true "one or more device mac addresses in csv format"
// @Param from query string false "utc date to start from, inclusive, in USO format. Default to 31 days ago."
// @Param to query string false "utc date to, exclusive, in USO format. Defaults to now."
// @Param minGallons query string false "filter events to have min gallons used, default 0"
// @Param minDuration query string false "filter events to have min duration in seconds, default 3.0"
// @Param offset query string false "how many record to skip, default 0"
// @Param limit query string false "maximum records to return, default 100"
// @Accept  application/json
// @Produce  application/json
// @Success 200 {object} TrendsReport
// @Failure 400 {object} HttpErrorResponse
// @Router /trends [get]
func trendsReportHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	macCsv := parseListAndCsv(r.URL.Query()["deviceId"])
	fromDate := tryParseDate(strings.Join(r.URL.Query()["from"], ""))
	toDate := tryParseDate(strings.Join(r.URL.Query()["to"], ""))
	minGals := reportMinGallons(r)
	minDuration := reportMinDuration(r)
	offset := httpQueryGetInt64(r, "offset", 0)
	limit := httpQueryGetInt64(r, "limit", DEFAULT_PAGE_SIZE)

	st := time.Now()

	if limit < 0 {
		limit = DEFAULT_PAGE_SIZE
	}

	if len(macCsv) == 0 {
		httpError(w, 400, "must include at least one deviceId query param", nil)
		return
	}
	for _, m := range macCsv {
		if !isValidMacAddress(m) {
			httpError(w, 400, "invalid mac address format: "+m, nil)
			return
		}
	}
	if fromDate.Year() < 2000 {
		fromDate = time.Now().UTC().Add(-31 * 24 * time.Hour).Truncate(time.Minute)
	}
	if toDate.Year() < 2000 {
		toDate = time.Now().UTC().Truncate(time.Minute).Add(time.Minute)
	}

	rv := TrendsReport{}
	rv.Arguments.DeviceId = macCsv
	rv.Arguments.From = fromDate
	rv.Arguments.To = toDate
	rv.Arguments.MinGallons = minGals
	rv.Arguments.MinDuration = minDuration
	rv.Items = make([]*DeviceTrendsReport, 0)

	for _, m := range macCsv {
		rv.Items = append(rv.Items, getDeviceTrendsReport(ctx, m, fromDate, toDate, minGals, minDuration, offset, limit))
	}

	et := time.Now()
	elapsed := et.Sub(st).Seconds()
	if elapsed > 2 {
		logWarn("trendsReportHandler: SLOW %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	} else {
		logDebug("trendsReportHandler: %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	}

	httpWrite(w, 200, rv)
}

func getDeviceTrendsReport(ctx context.Context, macAddress string, start time.Time, end time.Time, minGal float64, minDuration float64, offset int64, limit int64) *DeviceTrendsReport {
	dr := new(DeviceTrendsReport)
	dr.DeviceId = macAddress

	st := time.Now()

	if minGal < 0 {
		minGal = 0
	}
	if minDuration < 0 {
		minDuration = 0
	}

	rows, e := _pgCn.Query(ctx, `SELECT 
			id,
			start,
			"end",
			duration,
			gallons_total,
			incident_id
		FROM flodetect_events 
		WHERE 
			device_id = $1 AND 
			start >= $2 AND 
			"end"< $3 AND 
			gallons_total >= $4 AND 
			duration >= $7
		ORDER BY start DESC 
		OFFSET $5 LIMIT $6;`, macAddress, start, end, minGal, offset, limit, minDuration)
	if e != nil {
		dr.Error = "database error"
		logWarn("getDeviceTrendsReport: database error %v %v", macAddress, e.Error())
		return dr
	}
	defer rows.Close()

	dr.Events = make([]*TrendsEntry, 0)
	for rows.Next() {
		delta := &TrendsEntry{}

		e := rows.Scan(&delta.Id, &delta.StartAt, &delta.EndAt, &delta.Duration, &delta.TotalGallons, &delta.IncidentId)
		if e != nil {
			logWarn("getDeviceTrendsReport: error scanning row. %v %v", macAddress, e.Error())
		} else {
			if delta.IncidentId == _nilUUID {
				delta.IncidentId = ""
			}
			dr.Events = append(dr.Events, delta)
		}
	}

	et := time.Now()

	logDebug("getDeviceTrendsReport: %v returned %v events in %v sec", macAddress, len(dr.Events), et.Sub(st).Seconds())

	return dr
}

type TrendsReport struct {
	Arguments TrendsReportRequest   `json:"params"`
	Items     []*DeviceTrendsReport `json:"items"`
}

type DeviceTrendsReport struct {
	DeviceId string         `json:"deviceId"`
	Error    string         `json:"error,omitempty"`
	Events   []*TrendsEntry `json:"events"`
}

type TrendsEntry struct {
	Id           string    `json:"id"`
	DeviceId     string    `json:"deviceId,omitempty"`
	StartAt      time.Time `json:"startAt"`
	EndAt        time.Time `json:"endAt"`
	Duration     float64   `json:"duration"`
	TotalGallons float64   `json:"totalGal"`
	IncidentId   string    `json:"incidentId,omitempty"`
}

type TrendsReportRequest struct {
	DeviceId    []string  `json:"deviceId"`
	From        time.Time `json:"from"`
	To          time.Time `json:"to"`
	MinGallons  float64   `json:"minGallons"`
	MinDuration float64   `json:"minDuration"`
}
