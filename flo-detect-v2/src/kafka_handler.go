package main

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"
	"time"
)

// fixtureEventPostHandler godoc
// @Summary Produce kafka message for a FloDetect event
// @Description Produce kafka message for a FloDetect event
// @Tags Kafka
// @Accept  application/json
// @Param item body FloDetectEnvelope true "Event object, this will be sent to Kafka topic and ingested"
// @Produce  application/json
// @Success 202 {object} FloDetectEnvelope
// @Failure 400 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /kafka/event [post]
func fixtureEventPostHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	reqModel, err := getFloDetectRequestBody(r)
	if err != nil {
		httpError(w, 400, "unable to read request data", err)
		return
	}
	if reqModel == nil {
		httpError(w, 500, "nil body model", nil)
		return
	}

	modelErr := validateFloDetectFixtureEventModel(reqModel)
	if modelErr != nil {
		httpError(w, 400, "bad model input", modelErr)
		return
	}

	//reqModel.Id = uuid.New().String()
	reqModel.Event = EVENT_TYPE_FIXTURE
	reqModel.UnixTime = float64(time.Now().Unix())
	reqModel.Source = EVENT_SOURCE_API + "-event"

	_kafka.Publish(ctx, KAFKA_TOPIC_FLODETECT_EVENT, reqModel, []byte(reqModel.DeviceId))

	httpWrite(w, 202, reqModel)
}

// irrigationEventPostHandler godoc
// @Summary Produce kafka message for a FloDetect irrigation schedule
// @Description Produce kafka message for a FloDetect irrigation schedule
// @Tags Kafka
// @Accept  application/json
// @Param item body FloDetectEnvelope true "Irrigation schedule object, this will be sent to Kafka topic and ingested"
// @Produce  application/json
// @Success 202 {object} FloDetectEnvelope
// @Failure 400 {object} HttpErrorResponse
// @Failure 500 {object} HttpErrorResponse
// @Router /kafka/irrigation [post]
func irrigationEventPostHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	reqModel, err := getFloDetectRequestBody(r)
	if err != nil {
		httpError(w, 400, "unable to read request data", err)
		return
	}
	if reqModel == nil {
		httpError(w, 500, "nil body model", nil)
		return
	}

	modelErr := validateFloDetectIrrigationEventModel(reqModel)
	if modelErr != nil {
		httpError(w, 400, "bad model input", modelErr)
		return
	}

	//reqModel.Id = uuid.New().String()
	reqModel.Event = EVENT_TYPE_IRRIGATION
	reqModel.UnixTime = float64(time.Now().Unix())
	reqModel.Source = EVENT_SOURCE_API + "-event"

	_kafka.Publish(ctx, KAFKA_TOPIC_FLODETECT_EVENT, reqModel, []byte(reqModel.DeviceId))

	httpWrite(w, 202, reqModel)
}

func getFloDetectRequestBody(r *http.Request) (*FloDetectEnvelope, error) {
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
	rv := new(FloDetectEnvelope)
	err = json.Unmarshal(body, &rv)
	if err != nil {
		return nil, err
	}
	return rv, nil
}

type FloDetectEnvelope struct {
	Id         string                   `json:"id,omitempty" minLength:"24" maxLength:"38"`
	Event      string                   `json:"evt" enums:"fixture,irrigation"`
	DeviceId   string                   `json:"did" minLength:"12" maxLength:"12" example:"ff00aa11bb99"`
	UnixTime   float64                  `json:"ts" example:"1584495760"`
	Source     string                   `json:"src,omitempty" example:"api"`
	Fixture    *FloDetectFixtureData    `json:"fixture,omitempty"`
	Irrigation *FloDetectIrrigationData `json:"irrigation,omitempty"`
}

type FloDetectFixtureData struct {
	Detected []json.RawMessage `json:"detected"`
}

type FloDetectPredictedEvent struct {
	EventId       string                      `json:"evt_id,omitempty" minLength:"24" maxLength:"38" example:"c65baa35-0266-4cd4-91af-1803a44a4d22"`
	IncidentId    string                      `json:"i_id,omitempty" minLength:"24" maxLength:"38" example:"c65baa35-0266-4cd4-91af-1803a44a4d22"`
	StartUnixTime float64                     `json:"st" example:"1584495760"`
	EndUnixTime   float64                     `json:"et" example:"1584495760"`
	Gallons       float64                     `json:"gal" example:"2.83"`
	Duration      float64                     `json:"sec" example:"10.23"`
	Fixtures      []FloDetectPredictedFixture `json:"fix"`
}

type FloDetectPredictedFixture struct {
	Id         int     `json:"id" minimum:"0" maximum:"1000000"`
	Confidence float64 `json:"conf,omitempty" minimum:"0" maximum:"100"`
}

type FloDetectIrrigationData struct {
	DeviceSchedule []FloDetectIrrigationScheduleItem `json:"proposal"`
	UserSchedule   []FloDetectIrrigationScheduleItem `json:"user"`
}

type FloDetectIrrigationScheduleItem struct {
	StartTime string   `json:"s" example:"02:15"`
	EndTime   string   `json:"e" example:"14:30"`
	DayOfWeek []string `json:"d"`
}
