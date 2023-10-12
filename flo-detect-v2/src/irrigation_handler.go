package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/gorilla/mux"
)

// irrigationGetHandler godoc
// @Summary Retrieve irrigation schedule for a specific device
// @Description Retrieve irrigation schedule for a specific device
// @Tags Irrigation
// @Param mac path string true "mac address of the device"
// @Produce  application/json
// @Success 200 {object} IrrigationView
// @Failure 400 {object} HttpErrorResponse
// @Failure 404
// @Failure 500 {object} HttpErrorResponse
// @Router /irrigation/{mac} [get]
func irrigationGetHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	defer func(s time.Time) {
		sec := time.Now().Sub(s).Seconds()
		if sec >= 2 {
			logWarn("Irrigation handler took longer than expected! Took %v", sec)
		}
	}(time.Now())

	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	row, e := _pgCn.QueryRow(ctx, "SELECT "+
		"device_id,flodetect_schedule,flodetect_updated,user_schedule,user_updated "+
		" FROM flodetect_irrigation WHERE device_id=$1;",
		mac)

	if e != nil {
		httpError(w, 500, "unable to access database", e)
		return
	}

	rowMac := ""
	rowFloDetectJson := ""
	rowFloDetectTime := time.Time{}
	rowUserJson := ""
	rowUserTime := time.Time{}

	e = row.Scan(&rowMac, &rowFloDetectJson, &rowFloDetectTime, &rowUserJson, &rowUserTime)
	if e != nil && e == sql.ErrNoRows {
		httpError(w, 404, "device irrigation not found", nil)
		return
	}
	if e != nil {
		// sql: no rows in result set
		httpError(w, 500, "unable to read data", e)
		return
	}

	rv := IrrigationView{}
	rv.DeviceId = rowMac

	if len(rowUserJson) > 2 && rowUserTime.Year() > 2000 {
		rv.User = new(IrrigationScheduleView)
		rv.User.Updated = rowUserTime

		tmpSchDal := IrrigationScheduleDAL{}
		e := json.Unmarshal([]byte(rowUserJson), &tmpSchDal)
		if e != nil {
			httpError(w, 500, "error deserailzing user data", nil)
			return
		}

		for _, s := range tmpSchDal.Schedule {
			d := IrrigationTimeView{}
			d.Start = s.Start
			d.End = s.End
			d.DayOfWeek = s.DOW
			rv.User.Schedule = append(rv.User.Schedule, d)
		}
	}

	if len(rowFloDetectJson) > 2 && rowFloDetectTime.Year() > 2000 {
		rv.FloDetect = new(IrrigationScheduleView)
		rv.FloDetect.Updated = rowFloDetectTime

		tmpSchDal := IrrigationScheduleDAL{}
		e := json.Unmarshal([]byte(rowFloDetectJson), &tmpSchDal)
		if e != nil {
			httpError(w, 500, "error deserailzing flodetect data", nil)
			return
		}

		for _, s := range tmpSchDal.Schedule {
			d := IrrigationTimeView{}
			d.Start = s.Start
			d.End = s.End
			d.DayOfWeek = s.DOW
			rv.FloDetect.Schedule = append(rv.FloDetect.Schedule, d)
		}
	}

	httpWrite(w, 200, rv)
}

// irrigationPostHandler godoc
// @Summary Provide user irrigation schedule
// @Description Provide user irrigation schedule
// @Tags Irrigation
// @Accept  application/json
// @Param mac path string true "uuid of event"
// @Param item body IrrigationView true "User irrigation schedule"
// @Produce  application/json
// @Success 202
// @Failure 400 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /irrigation/{mac} [post]
func irrigationPostHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	reqModel, err := getIrrigationRequestBody(r)
	if err != nil {
		httpError(w, 400, "unable to read request data", err)
		return
	}
	if reqModel == nil {
		httpError(w, 500, "nil body model", nil)
		return
	}
	if !strings.EqualFold(reqModel.DeviceId, mac) {
		httpError(w, 400, "deviceId and url mac address mismatch", nil)
		return
	}
	if reqModel.User == nil || reqModel.User.Schedule == nil {
		httpError(w, 400, "user property is required", nil)
		return
	}
	if reqModel.FloDetect != nil {
		httpError(w, 400, "floDetect property cannot be set by API", nil)
		return
	}

	eventModel := FloDetectEnvelope{}
	eventModel.DeviceId = strings.ToLower(strings.TrimSpace(mac))
	eventModel.Id = uuid.New().String()
	eventModel.Event = EVENT_TYPE_IRRIGATION
	eventModel.UnixTime = float64(time.Now().Unix())
	eventModel.Source = EVENT_SOURCE_API + "-irrigation"
	eventModel.Irrigation = new(FloDetectIrrigationData)
	eventModel.Irrigation.UserSchedule = make([]FloDetectIrrigationScheduleItem, 0)

	for _, s := range reqModel.User.Schedule {
		d := FloDetectIrrigationScheduleItem{}
		d.StartTime = s.Start
		d.EndTime = s.End
		d.DayOfWeek = s.DayOfWeek

		e := validateTime(d)
		if e != nil {
			httpError(w, 400, "bad schedule data", e)
			return
		}

		eventModel.Irrigation.UserSchedule = append(eventModel.Irrigation.UserSchedule, d)
	}

	_kafka.Publish(ctx, KAFKA_TOPIC_FLODETECT_EVENT, eventModel, []byte(eventModel.DeviceId))

	httpWrite(w, 202, nil)

}

// irrigationDeleteHandler godoc
// @Summary Delete irrigation schedule for a specific device
// @Description Delete irrigation schedule for a specific device
// @Tags Irrigation
// @Param mac path string true "mac address of the device"
// @Produce  application/json
// @Success 200
// @Failure 400 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /irrigation/{mac} [delete]
func irrigationDeleteHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	_, e := _pgCn.ExecNonQuery(ctx, "DELETE FROM flodetect_irrigation WHERE device_id=$1;", mac)
	if e != nil {
		httpError(w, 500, "error deleting irrigation. "+mac, e)
		return
	}

	httpWrite(w, 200, nil)
}

func getIrrigationRequestBody(r *http.Request) (*IrrigationView, error) {
	if r == nil {
		return nil, errors.New("request is nil")
	}
	if r.Body == nil {
		return nil, errors.New("request body is nil")
	}
	if r.ContentLength <= 0 {
		return nil, errors.New("request body length is 0")
	}
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return nil, err
	}
	rv := new(IrrigationView)
	err = json.Unmarshal(body, &rv)
	if err != nil {
		return nil, err
	}
	return rv, nil
}

type IrrigationView struct {
	DeviceId  string                  `json:"deviceId" example:"ff00aa11bb22"`
	FloDetect *IrrigationScheduleView `json:"floDetect"`
	User      *IrrigationScheduleView `json:"user"`
}

type IrrigationScheduleView struct {
	Updated  time.Time            `json:"updatedAt"`
	Schedule []IrrigationTimeView `json:"schedule"`
}

type IrrigationTimeView struct {
	Start     string   `json:"startTime" example:"02:15"`
	End       string   `json:"endTime" example:"13:45"`
	DayOfWeek []string `json:"dayOfWeek" enums:"SU,MO,TU,WE,TH,FR,SA"`
}

type IrrigationScheduleDAL struct {
	Schedule []IrrigationTimeDAL `json:"schedule"`
}

type IrrigationTimeDAL struct {
	Start string   `json:"s" example:"02:15"`
	End   string   `json:"e" example:"13:45"`
	DOW   []string `json:"d" enums:"SU,MO,TU,WE,TH,FR,SA"`
}
