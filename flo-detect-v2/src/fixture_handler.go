package main

import (
	"context"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"
)

// fixtureReportHandler godoc
// @Summary Retrieve FloDetect fixtures for one or more devices based on date range
// @Description Retrieve FloDetect fixtures for one or more devices based on date range. Max of 1000 events per device is returned.
// @Tags Fixtures
// @Param deviceId query string true "one or more device mac addresses in csv format"
// @Param from query string false "utc date to start from, inclusive, in USO format. Default to 31 days ago."
// @Param to query string false "utc date to, exclusive, in USO format. Defaults to now."
// @Param minGallons query string false "filter events to have min gallons used, default 0"
// @Param minDuration query string false "filter events to have min duration in seconds, default 3.0"
// @Param lang query string false "language to use for the title properties. Default/fallback to 'en'."
// @Accept  application/json
// @Produce  application/json
// @Success 200 {object} FixtureReport
// @Failure 400 {object} HttpErrorResponse
// @Router /fixtures [get]
func fixtureReportHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	macCsv := parseListAndCsv(r.URL.Query()["deviceId"])
	fromDate := tryParseDate(strings.Join(r.URL.Query()["from"], ""))
	toDate := tryParseDate(strings.Join(r.URL.Query()["to"], ""))
	lang := strings.Join(r.URL.Query()["lang"], "")
	minGal := reportMinGallons(r)
	minDuration := reportMinDuration(r)
	st := time.Now()

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

	rv := FixtureReport{}
	rv.Arguments.DeviceId = macCsv
	rv.Arguments.From = fromDate
	rv.Arguments.To = toDate
	rv.Arguments.MinGallons = minGal
	rv.Arguments.MinDuration = minDuration
	rv.Items = make([]*DeviceFixtureReport, 0)

	for _, m := range macCsv {
		rv.Items = append(rv.Items, getDeviceFixtureReport(ctx, m, fromDate, toDate, minGal, minDuration))
		if len(rv.Items) > 0 {
			for _, x := range rv.Items {
				if len(x.Fixtures) > 0 {
					for _, y := range x.Fixtures {
						fillInFixtures(y, lang)
					}
				}
			}
		}
	}

	et := time.Now()
	elapsed := et.Sub(st).Seconds()
	if elapsed > 2 {
		logWarn("fixtureReportHandler: SLOW %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	} else {
		logDebug("fixtureReportHandler: %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	}

	httpWrite(w, 200, rv)
}

func getDeviceFixtureReport(ctx context.Context, macAddress string, fromDate time.Time, toDate time.Time, minGal float64, minDuration float64) *DeviceFixtureReport {
	dr := new(DeviceFixtureReport)
	dr.DeviceId = macAddress

	st := time.Now()

	if minGal < 0 {
		minGal = 0
	}
	if minDuration < 0 {
		minDuration = 0
	}

	rows, e := _pgCn.Query(ctx, `SELECT 
			CASE WHEN feedback_fixture_id > 0 THEN feedback_fixture_id ELSE predicted_fixture_id END AS final_fixture_id,
			SUM(gallons_total),
			SUM(duration),
			COUNT(id)
		FROM flodetect_events 
		WHERE 
			device_id = $1 AND 
			start >= $2 AND 
			"end" < $3 AND 
			gallons_total >= $4 AND 
			duration >= $5 AND
			feedback_fixture_id != 999 AND
			predicted_fixture_id != 999
		GROUP BY final_fixture_id;`, macAddress, fromDate, toDate, minGal, minDuration)

	if e != nil {
		dr.Error = "database error"
		logWarn("getDeviceFixtureReport: database error %v %v", macAddress, e.Error())
		return dr
	}
	defer rows.Close()

	dr.Fixtures = make([]*FixtureEntry, 0)

	for rows.Next() {
		delta := &FixtureEntry{}

		e := rows.Scan(&delta.Id, &delta.TotalGallons, &delta.TotalSeconds, &delta.Count)
		if e != nil {
			logWarn("getDeviceFixtureReport: error scanning row. %v %v", macAddress, e.Error())
		} else {
			dr.Fixtures = append(dr.Fixtures, delta)
		}
	}

	sort.Slice(dr.Fixtures, func(i, j int) bool { return dr.Fixtures[i].Id < dr.Fixtures[j].Id })

	et := time.Now()
	logDebug("getDeviceFixtureReport: %v returned %v events in %v sec", macAddress, len(dr.Fixtures), et.Sub(st).Seconds())

	return dr
}

func fillInFixtures(item *FixtureEntry, lang string) *FixtureEntry {
	if item == nil {
		return item
	}

	if item.Id > 0 {
		ok := false
		item.DisplayText, ok = getListValue(LIST_FLODETECT_PREDICTED, strconv.Itoa(item.Id), lang)
		if !ok {
			item.DisplayText, ok = getListValue(LIST_FLODETECT_FEEDBACK, strconv.Itoa(item.Id), lang)
		}
	}

	return item
}

type FixtureReport struct {
	Arguments EventsReportRequest    `json:"params"`
	Items     []*DeviceFixtureReport `json:"items"`
}

type DeviceFixtureReport struct {
	DeviceId string          `json:"deviceId"`
	Error    string          `json:"error,omitempty"`
	Fixtures []*FixtureEntry `json:"fixtures"`
}

type FixtureEntry struct {
	Id           int     `json:"id"`
	DisplayText  string  `json:"displayText"`
	Count        int     `json:"count"`
	TotalGallons float64 `json:"totalGallons"`
	TotalSeconds float64 `json:"totalSeconds"`
}
