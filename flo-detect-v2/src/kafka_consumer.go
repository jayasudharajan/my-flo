package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/sync/semaphore"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

const (
	EVENT_TYPE_FIXTURE                      = "fixture"
	EVENT_TYPE_IRRIGATION                   = "irrigation"
	EVENT_SOURCE_API                        = "api"
	PROC_HURDLE                             = 20
	ENVVAR_CONSUMER_MAX_CONCURRENT_WORKERS  = "CONSUMER_MAX_CONCURRENT_WORKERS"
	DEFAULT_CONSUMER_MAX_CONCURRENT_WORKERS = 4
)

var _kafkaConcurrencySemaphore *semaphore.Weighted
var _bgContext = context.Background()

func init() {

	maxWorkers, err := strconv.Atoi(getEnvOrDefault(ENVVAR_CONSUMER_MAX_CONCURRENT_WORKERS, fmt.Sprintf("%v", DEFAULT_CONSUMER_MAX_CONCURRENT_WORKERS)))
	if err != nil {
		maxWorkers = DEFAULT_CONSUMER_MAX_CONCURRENT_WORKERS
	}
	_kafkaConcurrencySemaphore = semaphore.NewWeighted(int64(maxWorkers))
}

func startFloDetectEventConsumer() error {
	_, err := _kafka.Subscribe(_kafkaGroupId, []string{KAFKA_TOPIC_FLODETECT_EVENT}, processFloDetectEventThrottled)
	if err != nil {
		return err
	}
	return nil
}

func processFloDetectEventThrottled(item *kafka.Message) {
	hasSem := false
	if e := _kafkaConcurrencySemaphore.Acquire(_bgContext, 1); e != nil {
		logWarn("processFloDetectEventThrottled: can't acquire sem: %v", e)
		time.Sleep(time.Millisecond)
	} else {
		hasSem = true
	}

	go func(m *kafka.Message, releaseSem bool) {
		if releaseSem {
			defer _kafkaConcurrencySemaphore.Release(1)
		}
		processFloDetectEvent(m)
	}(item, hasSem)
}

func processFloDetectEvent(item *kafka.Message) {
	defer panicRecover("processFloDetectEvent")
	if item == nil || len(item.Value) == 0 || item.TopicPartition.String() == "" {
		return
	}

	event := new(FloDetectEnvelope)
	err := json.Unmarshal(item.Value, &event)
	if err != nil {
		logWarn("processFloDetectEvent: error de-serializing envelope. %v", err.Error())
		return
	}
	if event == nil {
		logWarn("processFloDetectEvent: event object is nil")
		return
	}

	// Normalize the event string
	event.Event = strings.ToLower(strings.TrimSpace(event.Event))
	ctx, sp := tracing.InstaKafkaCtxExtractWithSpan(item, "brokers")
	defer sp.Finish()

	switch event.Event {
	case EVENT_TYPE_FIXTURE:
		processFloDetectFixtureEvent(ctx, event)
	case EVENT_TYPE_IRRIGATION:
		processFloDetectIrrigationEvent(ctx, event)
	default:
		logWarn("processFloDetectEvent: unknown event type: '%v'", event.Event)
	}
}

func processFloDetectFixtureEvent(ctx context.Context, eventEnvelope *FloDetectEnvelope) {
	err := validateFloDetectFixtureEventModel(eventEnvelope)
	if err != nil {
		logWarn("processFloDetectFixtureEvent: Error: %v", err)
		return
	}
	chronicle := newChronicle("processFloDetectFixtureEventStats")
	chronicle.addMeta("mac", eventEnvelope.DeviceId)
	chronicle.addMeta("len", len(eventEnvelope.Fixture.Detected))

	defer chronicle.flush(PROC_HURDLE)

	for _, rawEvent := range eventEnvelope.Fixture.Detected {
		chronicle.startStep("marshall")
		var evt FloDetectPredictedEvent
		_ = json.Unmarshal(rawEvent, &evt)

		if len(evt.Fixtures) == 0 {
			logWarn("processFloDetectFixtureEvent: detected fixture array is empty. %v", eventEnvelope.DeviceId)
			continue
		}
		dal := FloDetectFixtureDAL{}
		dal.Id = uuid.New().String()
		dal.DeviceId = eventEnvelope.DeviceId
		dal.Start = unixFloatToTime(evt.StartUnixTime).UTC()
		dal.End = unixFloatToTime(evt.EndUnixTime).UTC()
		dal.GallonsTotal = evt.Gallons
		dal.IncidentId = evt.IncidentId
		dal.Created = time.Now().UTC()
		dal.Updated = time.Now().UTC()
		dal.PredictedFixtureId = pickFixtureId(evt.Fixtures)
		dal.RawJson = string(rawEvent)
		dal.Duration = evt.Duration
		if dal.Duration <= 0 {
			dal.Duration = dal.End.Sub(dal.Start).Seconds()
		}

		if dal.Start.Year() < 2000 || dal.Start.Year() > 2100 {
			logWarn("processFloDetectFixtureEvent: invalid event start date. %v %v", dal.DeviceId, dal.Start.Format(time.RFC3339))
			continue
		} else if dal.End.Year() < 2000 || dal.End.Year() > 2100 {
			logWarn("processFloDetectFixtureEvent: invalid event end date. %v %v", dal.DeviceId, dal.Start.Format(time.RFC3339))
			continue
		}
		chronicle.startStep("dbStore")
		err := insertFloDetectFixtureRecord(ctx, &dal)
		if err != nil {
			logError("processFloDetectFixtureEvent: %v", err)
			return
		}
		chronicle.startStep("firestore")
		updateFirestore(ctx, &dal)

		chronicle.startStep("notify")
		writeEventCreatedActivity(ctx, &dal)

		logDebug("processFloDetectFixtureEvent: New FloDetect fixture event. mac: %v fix: %v id: %v", dal.DeviceId, dal.PredictedFixtureId, dal.Id)
	}
}

func pickFixtureId(fixArray []FloDetectPredictedFixture) int {
	if len(fixArray) == 0 {
		return 0
	}
	if len(fixArray) == 1 {
		return fixArray[0].Id
	}
	sort.Slice(fixArray, func(i, j int) bool { return fixArray[i].Confidence > fixArray[j].Confidence })
	return fixArray[0].Id
}

func updateFirestore(ctx context.Context, item *FloDetectFixtureDAL) {
	v := map[string]interface{}{
		"floDetect": map[string]interface{}{
			"latestEvent": map[string]interface{}{
				"id":      item.Id,
				"startAt": item.Start.UTC().Format(time.RFC3339),
				"endAt":   item.End.UTC().Format(time.RFC3339),
				"predicted": map[string]interface{}{
					"id": item.PredictedFixtureId,
				},
				"totalGal": item.GallonsTotal,
				"incident": map[string]interface{}{
					"id": item.IncidentId,
				},
			},
		},
	}

	fireWriterDevice(ctx, item.DeviceId, v)
}

func writeEventCreatedActivity(ctx context.Context, item *FloDetectFixtureDAL) {
	v := map[string]interface{}{
		"id":      item.Id,
		"startAt": item.Start.UTC().Format(time.RFC3339),
		"endAt":   item.End.UTC().Format(time.RFC3339),
		"predicted": map[string]interface{}{
			"id": item.PredictedFixtureId,
		},
		"totalGal": item.GallonsTotal,
		"incident": map[string]interface{}{
			"id": item.IncidentId,
		},
	}

	writeActivity(ctx, item.DeviceId, "flodetect-event", "created", item.Id, v)
}

func writeEventFeedbackActivity(ctx context.Context, macAddress string, id string, feedbackId int, feedbackUserId string) {
	v := map[string]interface{}{
		"id": id,
		"feedback": map[string]interface{}{
			"id": feedbackId,
			"user": map[string]interface{}{
				"id": feedbackUserId,
			},
		},
	}

	writeActivity(ctx, macAddress, "flodetect-event", "updated", id, v)
}

func writeActivity(ctx context.Context, macAddress string, itemType string, action string, pk string, item interface{}) {

	o := map[string]interface{}{
		"date":   time.Now().UTC().Format(time.RFC3339),
		"type":   itemType,
		"action": action,
		"id":     pk,
	}

	if item != nil {
		o["item"] = item
	}

	_kafka.Publish(ctx, "flodetect-activity-v2", o, []byte(macAddress))
}

func insertFloDetectFixtureRecord(ctx context.Context, item *FloDetectFixtureDAL) error {
	if len(item.IncidentId) == 0 {
		item.IncidentId = _nilUUID
	}
	_, e := _pgCn.ExecNonQuery(ctx, `INSERT INTO flodetect_events 
		(id,device_id,start,"end",duration,gallons_total,incident_id,created,updated,predicted_fixture_id,raw)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) ON CONFLICT DO NOTHING;`,
		item.Id,
		item.DeviceId,
		item.Start,
		item.End,
		item.Duration,
		item.GallonsTotal,
		item.IncidentId,
		item.Created,
		item.Updated,
		item.PredictedFixtureId,
		item.RawJson)
	if e != nil {
		logWarn("insertFloDetectFixtureRecord: error writing data for %v %v %v", item.DeviceId, e.Error(), item.RawJson)
		return e
	}
	return nil
}

func processFloDetectIrrigationEvent(ctx context.Context, eventEnvelope *FloDetectEnvelope) {
	hasErr := validateFloDetectIrrigationEventModel(eventEnvelope)
	if hasErr != nil {
		logWarn("processFloDetectIrrigationEvent: Error: %v", hasErr.Error())
		return
	}

	updated := false

	chronicle := newChronicle("processFloDetectIrrigationEventStats")
	chronicle.addMeta("mac", eventEnvelope.DeviceId)
	defer chronicle.flush(PROC_HURDLE)

	if eventEnvelope.Irrigation.DeviceSchedule != nil {
		chronicle.startStep("marshall")
		tmp := map[string]interface{}{
			"schedule": eventEnvelope.Irrigation.DeviceSchedule,
		}
		tmpJson, e := json.Marshal(tmp)

		chronicle.startStep("dbStore")
		if e == nil {
			_, e = _pgCn.ExecNonQuery(ctx, `INSERT INTO flodetect_irrigation 
			(device_id, flodetect_schedule, flodetect_updated) VALUES ($1,$2,$3)
			ON CONFLICT (device_id) DO UPDATE SET flodetect_schedule=$2, flodetect_updated=$3;
			`,
				eventEnvelope.DeviceId,
				tmpJson,
				time.Now().UTC())

			if e != nil {
				logWarn("processFloDetectIrrigationEvent: error saving device irrigation schedule. %v %v", eventEnvelope.DeviceId, e.Error())
			} else {
				updated = true
			}

		} else {
			logWarn("processFloDetectIrrigationEvent: error serializing device schedule. %v %v", eventEnvelope.DeviceId, e.Error())
		}
	}

	// TODO: After processing user schedule, we must send it to the device
	if eventEnvelope.Irrigation.UserSchedule != nil {
		chronicle.startStep("marshall")
		tmp := map[string]interface{}{
			"schedule": eventEnvelope.Irrigation.UserSchedule,
		}
		tmpJson, e := json.Marshal(tmp)
		chronicle.startStep("dbStore")
		if e == nil {
			_, e = _pgCn.ExecNonQuery(ctx, `INSERT INTO flodetect_irrigation 
			(device_id, user_schedule, user_updated) VALUES ($1,$2,$3)
			ON CONFLICT (device_id) DO UPDATE SET user_schedule=$2, user_updated=$3;
			`,
				eventEnvelope.DeviceId,
				tmpJson,
				time.Now().UTC())

			if e != nil {
				logWarn("processFloDetectIrrigationEvent: error saving user irrigation schedule. %v %v", eventEnvelope.DeviceId, e.Error())
			} else {
				updated = true
			}
		} else {
			logWarn("processFloDetectIrrigationEvent: error serializing user schedule. %v %v", eventEnvelope.DeviceId, e.Error())
		}
	}

	if updated {
		chronicle.startStep("notify")
		writeIrrigationUpdatedActivity(ctx, eventEnvelope)
	}
}

func writeIrrigationUpdatedActivity(ctx context.Context, item *FloDetectEnvelope) {
	if item == nil || item.Irrigation == nil {
		return
	}

	writeActivity(ctx, item.DeviceId, "flodetect-irrigation", "updated", item.DeviceId, nil)
}

type FloDetectFixtureDAL struct {
	Id                 string
	DeviceId           string
	Start              time.Time
	End                time.Time
	Duration           float64
	GallonsTotal       float64
	IncidentId         string
	Created            time.Time
	Updated            time.Time
	PredictedFixtureId int
	FeedbackFixtureId  int
	RawJson            string
}

func validateFloDetectFixtureEventModel(reqModel *FloDetectEnvelope) error {
	if reqModel == nil {
		return errors.New("nil model")
	}
	if reqModel.Fixture == nil || len(reqModel.Fixture.Detected) == 0 {
		return errors.New("fixture property is missing or incomplete")
	}
	if !isValidMacAddress(reqModel.DeviceId) {
		return errors.New("did propety is not a valid mac address")
	}
	for _, rawEvent := range reqModel.Fixture.Detected {
		var fx FloDetectPredictedEvent
		if err := json.Unmarshal(rawEvent, &fx); err != nil {
			return fmt.Errorf("cannot unmarshal fixture - %v", err)
		}
		if fx.StartUnixTime <= 0 || fx.EndUnixTime <= 0 {
			return errors.New("fixture 'st' and 'et' must be a valid unix timestamp")
		}
		if len(fx.Fixtures) == 0 {
			return errors.New("fixtures array property must have at least one item")
		}
		for _, pred := range fx.Fixtures {
			if pred.Id <= 0 {
				return errors.New("fixtures id must be greater than 0")
			}
		}
		if len(fx.IncidentId) > 0 {
			_, e := uuid.Parse(fx.IncidentId)
			if e != nil {
				return errors.New("alert_id must be a valid UUID - any version")
			}
		}
	}

	return nil
}

var validDayOfWeekValues = map[string]bool{
	"SU": true,
	"MO": true,
	"TU": true,
	"WE": true,
	"TH": true,
	"FR": true,
	"SA": true,
}

func validateFloDetectIrrigationEventModel(reqModel *FloDetectEnvelope) error {
	if reqModel == nil {
		return errors.New("nil model")
	}
	if reqModel.Irrigation == nil {
		return errors.New("irrigation property is missing or incomplete")
	}
	if reqModel.Irrigation.DeviceSchedule == nil && reqModel.Irrigation.UserSchedule == nil {
		return errors.New("proposal and/or user schedule is required")
	}

	if !isValidMacAddress(reqModel.DeviceId) {
		return errors.New("did propety is not a valid mac address")
	}
	for _, fx := range reqModel.Irrigation.DeviceSchedule {
		if len(fx.StartTime) != 5 {
			return errors.New("irrigation 'st' and 'et' must be a valid time format. 'hh:mm'")
		}
		if len(fx.EndTime) != 5 {
			return errors.New("irrigation 'st' and 'et' must be a valid time format. 'hh:mm'")
		}
		if len(fx.DayOfWeek) > 0 {
			for _, dow := range fx.DayOfWeek {
				if !validDayOfWeekValues[strings.ToUpper(dow)] {
					return errors.New("irrigation 'dow' one or more items is invalid")
				}
			}
		}
	}
	for _, fx := range reqModel.Irrigation.UserSchedule {
		e := validateTime(fx)
		if e != nil {
			return e
		}
	}

	return nil
}

func validateTime(fx FloDetectIrrigationScheduleItem) error {
	if len(fx.StartTime) != 5 {
		return errors.New("irrigation start and end times must be a valid time format. 'hh:mm'")
	}
	if len(fx.EndTime) != 5 {
		return errors.New("irrigation start and end times must be a valid time format. 'hh:mm'")
	}
	if len(fx.DayOfWeek) > 0 {
		for _, dow := range fx.DayOfWeek {
			if !validDayOfWeekValues[strings.ToUpper(dow)] {
				return errors.New("irrigation days contains one or more invalid items")
			}
		}
	}
	return nil
}
