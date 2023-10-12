package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

const DEFAULT_PAGE_SIZE = 100

// eventReportHandler godoc
// @Summary Retrieve FloDetect events for one or more devices based on date range
// @Description Retrieve FloDetect events for one or more devices based on date range. Max of 1000 events per device is returned.
// @Tags Events
// @Param deviceId query string true "one or more device mac addresses in csv format"
// @Param from query string false "utc date to start from, inclusive, in USO format. Default to 31 days ago."
// @Param to query string false "utc date to, exclusive, in USO format. Defaults to now."
// @Param minGallons query string false "filter events to have min gallons used, default 0"
// @Param minDuration query string false "filter events to have min duration in seconds, default 3.0"
// @Param offset query string false "how many record to skip, default 0"
// @Param limit query string false "maximum records to return, default 100"
// @Param lang query string false "language to use for the title properties. Default/fallback to 'en'."
// @Accept  application/json
// @Produce  application/json
// @Success 200 {object} EventsReport
// @Failure 400 {object} HttpErrorResponse
// @Router /events [get]
func eventReportHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	macCsv := parseListAndCsv(r.URL.Query()["deviceId"])
	fromDate := tryParseDate(strings.Join(r.URL.Query()["from"], ""))
	toDate := tryParseDate(strings.Join(r.URL.Query()["to"], ""))
	lang := strings.Join(r.URL.Query()["lang"], "")
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

	rv := EventsReport{}
	rv.Arguments.DeviceId = macCsv
	rv.Arguments.From = fromDate
	rv.Arguments.To = toDate
	rv.Arguments.MinGallons = minGals
	rv.Arguments.MinDuration = minDuration
	rv.Items = make([]*DeviceEventsReport, 0)

	for _, m := range macCsv {
		rv.Items = append(rv.Items, getDeviceEventsReport(ctx, m, fromDate, toDate, minGals, minDuration, offset, limit))

		if len(rv.Items) > 0 {
			for _, x := range rv.Items {
				if len(x.Events) > 0 {
					for _, y := range x.Events {
						fillInNames(y, lang)
					}
				}
			}
		}

	}

	et := time.Now()
	elapsed := et.Sub(st).Seconds()
	if elapsed > 2 {
		logWarn("eventReportHandler: SLOW %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	} else {
		logDebug("eventReportHandler: %.3f sec %v", elapsed, tryToJson(rv.Arguments))
	}

	httpWrite(w, 200, rv)
}

// eventGetHandler godoc
// @Summary Retrieve specific FloDetect event by ID (uuid)
// @Description Retrieve specific FloDetect event by ID (uuid)
// @Tags Events
// @Param id path string true "uuid of event"
// @Accept  json
// @Produce  application/json
// @Success 200 {object} EventsEntry
// @Failure 400 {object} HttpErrorResponse
// @Failure 404
// @Failure 500 {object} HttpErrorResponse
// @Router /events/{id} [get]
func eventGetHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	idString := mux.Vars(r)["id"]
	id, e := uuid.Parse(idString)
	if e != nil {
		httpError(w, 400, "invalid id format", nil)
		return
	}
	lang := strings.Join(r.URL.Query()["lang"], "")

	rows, e := _pgCn.Query(ctx, `SELECT 
			id,
			device_id,
			start,
			"end",
			duration,
			gallons_total,
			incident_id,
			predicted_fixture_id,
			feedback_fixture_id,
			feedback_user_id 
		FROM flodetect_events 
		WHERE id=$1;`, id.String())

	if e != nil {
		logWarn("eventGetHandler: database error %v %v", id.String(), e.Error())
		httpError(w, 500, "database error", e)
		return
	}
	defer rows.Close()

	if rows.Next() {
		delta := &EventsEntry{}

		e := rows.Scan(&delta.Id, &delta.DeviceId, &delta.StartAt, &delta.EndAt, &delta.Duration, &delta.TotalGallons, &delta.IncidentId, &delta.PredictedId, &delta.FeedbackId, &delta.FeedbackUserId)
		if e != nil {
			logWarn("eventGetHandler: error scanning row. %v %v", id.String(), e.Error())
			httpError(w, 500, "error reading record", e)
			return
		} else {
			if delta.IncidentId == _nilUUID {
				delta.IncidentId = ""
			}
			if delta.FeedbackUserId == _nilUUID {
				delta.FeedbackUserId = ""
			}

			httpWrite(w, 200, fillInNames(delta, lang))
			return
		}
	} else {
		httpWrite(w, 404, nil)
		return
	}
}

func fillInNames(item *EventsEntry, lang string) *EventsEntry {
	if item == nil {
		return item
	}

	if item.PredictedId > 0 {
		item.PredictedDisplayText, _ = getListValue(LIST_FLODETECT_PREDICTED, strconv.Itoa(item.PredictedId), lang)
	}

	if item.FeedbackId > 0 {
		item.FeedbackDisplayText, _ = getListValue(LIST_FLODETECT_FEEDBACK, strconv.Itoa(item.FeedbackId), lang)
	}

	return item
}

// eventPostHandler godoc
// @Summary Provide user feedback to the event
// @Description Provide user feedback to the event
// @Tags Events
// @Accept  application/json
// @Param id path string true "uuid of event"
// @Param force query string false "if set to true, will override previous feedback (override response 409)"
// @Param item body EventsFeedbackRequest true "User feedback values"
// @Produce  application/json
// @Success 200
// @Failure 400 {object} HttpErrorResponse
// @Failure 409 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /events/{id} [post]
func eventPostHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, e := uuid.Parse(mux.Vars(r)["id"])
	if e != nil {
		httpError(w, http.StatusBadRequest, "invalid id format", nil)
		return
	}
	feedback := new(EventsFeedbackRequest)
	if e = json.NewDecoder(r.Body).Decode(&feedback); e != nil {
		httpError(w, http.StatusInternalServerError, "unable to read body", e)
		return
	} else if feedback.FeedbackId == nil || *feedback.FeedbackId < 0 {
		httpError(w, http.StatusBadRequest, "feedbackId is missing or invalid", nil)
		return
	}

	fid, uid := *feedback.FeedbackId, ""
	if feedback.FeedbackUserId == nil || len(*feedback.FeedbackUserId) == 0 {
		uid = _nilUUID
	} else {
		if x, e := uuid.Parse(*feedback.FeedbackUserId); e == nil {
			uid = x.String()
		} else {
			httpError(w, http.StatusBadRequest, "feedbackUserId is invalid", nil)
			return
		}
	}

	existingFeedbackId := 0
	existingMacAddress, existingUserId := "", ""
	selectQuery := "SELECT feedback_fixture_id,device_id,feedback_user_id FROM flodetect_events WHERE id=$1"
	if foundRow, e := _pgCn.QueryRow(ctx, selectQuery, id); e != nil {
		httpError(w, http.StatusInternalServerError, "query error for id "+id.String(), e)
		return
	} else if e = foundRow.Scan(&existingFeedbackId, &existingMacAddress, &existingUserId); e != nil {
		if e.Error() == "sql: no rows in result set" {
			httpError(w, http.StatusNotFound, "event not found for "+id.String(), nil)
		} else {
			httpError(w, http.StatusInternalServerError, "scan error for "+id.String(), e)
		}
		return
	}
	force := strings.EqualFold(strings.Join(r.URL.Query()["force"], ""), "true")
	prevFeedbackSameUser := strings.EqualFold(uid, existingUserId)
	if !force && existingFeedbackId > 0 && !prevFeedbackSameUser {
		err := fmt.Errorf("user feedback already submitted for event id %v", id)
		httpError(w, http.StatusConflict, err.Error(), err)
		return
	}

	var sql string
	if force {
		sql = fmt.Sprintf(`UPDATE flodetect_events 
			SET feedback_fixture_id=%v, feedback_user_id='%v', updated=now()
			WHERE id='%v';`, fid, uid, id.String())
	} else {
		sql = fmt.Sprintf(`UPDATE flodetect_events 
			SET feedback_fixture_id=%v, feedback_user_id='%v', updated=now()
			WHERE id='%v' AND (feedback_fixture_id=0 OR feedback_user_id='%v');`, fid, uid, id.String(), uid)
	}
	sql += fmt.Sprintf(`
	INSERT INTO flodetect_events_feedback (
		id, device_id, "start", "end", duration, gallons_total, incident_id, created, updated, 
		predicted_fixture_id, feedback_fixture_id, feedback_user_id, raw
	) SELECT 
		id, device_id, "start", "end", duration, gallons_total, incident_id, created, updated, 
		predicted_fixture_id, feedback_fixture_id, feedback_user_id, raw
    FROM flodetect_events WHERE id='%v' `, id.String())
	if force || prevFeedbackSameUser {
		sql += fmt.Sprintf(` ON CONFLICT (id) DO UPDATE 
			SET feedback_fixture_id=%v, feedback_user_id='%v', updated=now();`, fid, uid)
	} else {
		sql += ` ON CONFLICT (id) DO NOTHING; `
	}
	if x, e := _pgCn.ExecNonQuery(ctx, sql); e != nil {
		httpError(w, http.StatusInternalServerError, "database write error for id "+id.String(), e)
		return
	} else if x != nil {
		ra, _ := x.RowsAffected()
		if ra > 0 {
			writeEventFeedbackActivity(ctx, existingMacAddress, id.String(), fid, uid)
			httpWrite(w, http.StatusOK, nil)
		}
	}
	httpWrite(w, http.StatusNoContent, nil)
}

// eventDeleteHandler godoc
// @Summary Delete specific FloDetect event by ID (uuid)
// @Description Delete specific FloDetect event by ID (uuid)
// @Tags Events
// @Param id path string true "uuid of event"
// @Accept  json
// @Produce  application/json
// @Success 200
// @Failure 400 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /events/{id} [delete]
func eventDeleteHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, e := uuid.Parse(mux.Vars(r)["id"])
	if e != nil {
		httpError(w, 400, "invalid id format", nil)
		return
	}
	sql := fmt.Sprintf(`DELETE FROM flodetect_events WHERE id='%v';
	DELETE FROM flodetect_events_feedback WHERE id='%v';`, id.String(), id.String())
	if _, e = _pgCn.ExecNonQuery(ctx, sql); e != nil {
		httpError(w, 500, "database error", e)
		return
	}
	httpWrite(w, 200, nil)
}

func getDeviceEventsReport(ctx context.Context, macAddress string, start time.Time, end time.Time, minGal float64, minDuration float64, offset int64, limit int64) *DeviceEventsReport {
	dr := new(DeviceEventsReport)
	dr.DeviceId = macAddress

	st := time.Now()

	// TODO: need to introduce caching
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
			incident_id,
			predicted_fixture_id,
			feedback_fixture_id,
			feedback_user_id
		FROM flodetect_events 
		WHERE 
			device_id=$1 AND 
			start>=$2 AND 
			"end"<$3 AND 
			gallons_total >= $4 AND 
			duration >= $7 AND
			predicted_fixture_id != 999 AND
			feedback_fixture_id != 999
		ORDER BY start DESC 
		OFFSET $5 LIMIT $6;`, macAddress, start, end, minGal, offset, limit, minDuration)
	if e != nil {
		dr.Error = "database error"
		logWarn("getDeviceEventsReport: database error %v %v", macAddress, e.Error())
		return dr
	}
	defer rows.Close()

	dr.Events = make([]*EventsEntry, 0)
	for rows.Next() {
		delta := &EventsEntry{}

		e := rows.Scan(&delta.Id, &delta.StartAt, &delta.EndAt, &delta.Duration, &delta.TotalGallons, &delta.IncidentId, &delta.PredictedId, &delta.FeedbackId, &delta.FeedbackUserId)
		if e != nil {
			logWarn("getDeviceEventsReport: error scanning row. %v %v", macAddress, e.Error())
		} else {
			if delta.IncidentId == _nilUUID {
				delta.IncidentId = ""
			}
			if delta.FeedbackUserId == _nilUUID {
				delta.FeedbackUserId = ""
			}

			dr.Events = append(dr.Events, delta)
		}
	}

	et := time.Now()

	logDebug("getDeviceEventsReport: %v returned %v events in %v sec", macAddress, len(dr.Events), et.Sub(st).Seconds())

	return dr
}

type EventsReport struct {
	Arguments EventsReportRequest   `json:"params"`
	Items     []*DeviceEventsReport `json:"items"`
}

type DeviceEventsReport struct {
	DeviceId string         `json:"deviceId"`
	Error    string         `json:"error,omitempty"`
	Events   []*EventsEntry `json:"events"`
}

type EventsEntry struct {
	Id                   string    `json:"id"`
	DeviceId             string    `json:"deviceId,omitempty"`
	StartAt              time.Time `json:"startAt"`
	EndAt                time.Time `json:"endAt"`
	Duration             float64   `json:"duration"`
	TotalGallons         float64   `json:"totalGal"`
	PredictedId          int       `json:"predictedId"`
	IncidentId           string    `json:"incidentId,omitempty"`
	PredictedDisplayText string    `json:"predictedDisplayText,omitempty"`
	FeedbackId           int       `json:"feedbackId,omitempty"`
	FeedbackDisplayText  string    `json:"feedbackDisplayText,omitempty"`
	FeedbackUserId       string    `json:"feedbackUserId,omitempty"`
}

type EventsReportRequest struct {
	DeviceId    []string  `json:"deviceId"`
	From        time.Time `json:"from"`
	To          time.Time `json:"to"`
	MinGallons  float64   `json:"minGallons"`
	MinDuration float64   `json:"minDuration"`
}

type EventsFeedbackRequest struct {
	FeedbackId     *int    `json:"feedbackId,omitempty" minimum:"0" maximum:"1000000"`
	FeedbackUserId *string `json:"feedbackUserId,omitempty" minLength:"24" maxLength:"38" example:"c65baa35-0266-4cd4-91af-1803a44a4d22"`
}
