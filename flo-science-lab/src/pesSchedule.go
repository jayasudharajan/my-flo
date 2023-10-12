package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/gorilla/mux"
	"github.com/robfig/cron/v3"
	ics "gitlab.com/flotechnologies/flo-science-lab/ical"
)

const SYSTEM_MODE_HOME string = "home"
const SYSTEM_MODE_AWAY string = "away"
const SYSTEM_MODE_SLEEP string = "sleep"
const DEFAULT_SHUTOFF_DELAY int = 300

type DirectiveBaseEnvelope struct {
	Id        string `json:"id"`
	Directive string `json:"directive"`
	DeviceId  string `json:"device_id"`
}

type DirectiveResponseEnvelope struct {
	Id        string                 `json:"id"`
	Directive string                 `json:"directive"`
	DeviceId  string                 `json:"device_id"`
	Data      map[string]interface{} `json:"data"`
}

type PesHardwareDirectiveModel struct {
	SystemMode string                   `json:"sm"`
	Schedules  []PesSettingsHwItemModel `json:"schedules"`
}

type PesSettingsHwItemModel struct {
	Name               string  `json:"name"`
	MaxDuration        float32 `json:"max_duration"`
	MaxRate            float32 `json:"max_rate"`
	MaxRateDuration    float32 `json:"max_rate_duration"`
	MaxVolume          float32 `json:"max_volume"`
	AutoShutOffEnabled *bool   `json:"auto_shut_off_enabled"`
	AutoShutOffDelay   *int    `json:"auto_shut_off_delay"`
	Schedule           string  `json:"schedule"`
}

type PesDataDAL struct {
	MacAddress       string
	ScheduleDirty    int
	ScheduleLastSent time.Time
}

func postPesScheduleHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	scheduleModel, err := parseScheduleModel(r)
	if err != nil {
		httpError(w, 400, "input body", err)
		return
	}
	if scheduleModel == nil {
		httpError(w, 500, "input item nil", nil)
		return
	}
	if len(scheduleModel.Id) != 0 {
		httpError(w, 400, "id property is set - can't create", nil)
		return
	}
	if len(scheduleModel.Name) == 0 {
		httpError(w, 400, "name property is empty", nil)
		return
	}
	if len(scheduleModel.Name) > 255 {
		httpError(w, 400, "name property is too long, max 255", nil)
		return
	}
	if len(scheduleModel.Mode) == 0 {
		httpError(w, 400, "mode property is empty", nil)
		return
	}
	if len(scheduleModel.StartTime) < 4 {
		httpError(w, 400, "startTime must be a valid time format. e.g. 12:42, 18:24, 5:12pm", nil)
		return
	}
	if len(scheduleModel.EndTime) < 4 {
		httpError(w, 400, "endTime must be a valid time format. e.g. 2:42, 18:24, 5:12pm", nil)
		return
	}

	// Validate mode
	scheduleModel.Mode = strings.ToLower(strings.TrimSpace(scheduleModel.Mode))
	if !strings.EqualFold(scheduleModel.Mode, SYSTEM_MODE_HOME) && !strings.EqualFold(scheduleModel.Mode, SYSTEM_MODE_AWAY) {
		httpError(w, 400, "mode property is invalid (home and away supported)", nil)
		return
	}

	// Fix name
	scheduleModel.Name = strings.TrimSpace(scheduleModel.Name)

	// Fix time input
	scheduleModel.StartTime = parseTimeMinuteMilitary(parseTimeString(scheduleModel.StartTime))
	scheduleModel.EndTime = parseTimeMinuteMilitary(parseTimeString(scheduleModel.EndTime))

	if scheduleModel.ShutoffDelay == nil {
		sec := DEFAULT_SHUTOFF_DELAY
		scheduleModel.ShutoffDelay = &sec // Default number of seconds before shutoff
	}
	if *scheduleModel.ShutoffDelay < 0 || *scheduleModel.ShutoffDelay > 3600 {
		httpError(w, 400, "shutoff delay must be between 0 and 3600", nil)
		return
	}

	scheduleModel.EventLimits.FlowRateDuration = scheduleModel.EventLimits.getValidFlowRateDuration()

	if scheduleModel.ShutoffDisabled == nil {
		f := false
		scheduleModel.ShutoffDisabled = &f
	}

	newItem, err := insertScheduleDb(mac, scheduleModel, false)
	if err != nil {
		errStr := err.Error()

		if strings.Contains(errStr, "duplicate key value violates unique constraint") {
			httpError(w, 409, "duplicate record. device+mode+start+end+order is unique.", nil)
		} else {
			httpError(w, 500, "db error", err)
		}

		return
	}

	if newItem != nil {
		newItem.ICalString = toIcal("", mac, newItem)
	}

	httpWrite(w, 201, newItem)
}

func replacePesScheduleHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	id := mux.Vars(r)["id"]
	id = strings.ToLower(strings.TrimSpace(strings.Replace(id, "-", "", -1)))
	if len(id) != 32 {
		httpError(w, 400, "invalid schedule id", nil)
		return
	}
	scheduleModel, err := parseScheduleModel(r)
	if err != nil {
		httpError(w, 400, "input body", err)
		return
	}
	if scheduleModel == nil {
		httpError(w, 500, "input item nil", nil)
		return
	}
	if !strings.EqualFold(id, scheduleModel.Id) {
		httpError(w, 400, "id property does not match url", nil)
		return
	}
	if len(scheduleModel.Name) == 0 {
		httpError(w, 400, "name property is empty", nil)
		return
	}
	if len(scheduleModel.Name) > 255 {
		httpError(w, 400, "name property is too long, max 255", nil)
		return
	}
	if len(scheduleModel.Mode) == 0 {
		httpError(w, 400, "mode property is empty", nil)
		return
	}
	if len(scheduleModel.StartTime) < 4 {
		httpError(w, 400, "startTime must be a valid time format. e.g. 12:42, 18:24, 5:12pm", nil)
		return
	}
	if len(scheduleModel.EndTime) < 4 {
		httpError(w, 400, "endTime must be a valid time format. e.g. 2:42, 18:24, 5:12pm", nil)
		return
	}

	// Validate mode
	scheduleModel.Mode = strings.ToLower(strings.TrimSpace(scheduleModel.Mode))
	if !strings.EqualFold(scheduleModel.Mode, SYSTEM_MODE_HOME) && !strings.EqualFold(scheduleModel.Mode, SYSTEM_MODE_AWAY) {
		httpError(w, 400, "mode property is invalid (home and away supported)", nil)
		return
	}

	// Fix name
	scheduleModel.Name = strings.TrimSpace(scheduleModel.Name)

	// Fix time input
	scheduleModel.StartTime = parseTimeMinuteMilitary(parseTimeString(scheduleModel.StartTime))
	scheduleModel.EndTime = parseTimeMinuteMilitary(parseTimeString(scheduleModel.EndTime))

	if scheduleModel.ShutoffDelay == nil {
		sec := DEFAULT_SHUTOFF_DELAY
		scheduleModel.ShutoffDelay = &sec // Default number of seconds before shutoff
	}
	if *scheduleModel.ShutoffDelay < 0 || *scheduleModel.ShutoffDelay > 3600 {
		httpError(w, 400, "shutoff delay must be between 0 and 3600", nil)
		return
	}
	if scheduleModel.ShutoffDisabled == nil {
		f := false
		scheduleModel.ShutoffDisabled = &f
	}

	scheduleModel.EventLimits.FlowRateDuration = scheduleModel.EventLimits.getValidFlowRateDuration()

	updated, err := updateScheduleDb(mac, scheduleModel)
	if err != nil {
		errStr := err.Error()

		if strings.Contains(errStr, "duplicate key value violates unique constraint") {
			httpError(w, 409, "duplicate record. device+mode+start+end+order is unique.", nil)
		} else {
			httpError(w, 500, "db error", err)
		}
		return
	}

	if updated {
		httpWrite(w, 200, scheduleModel)
	} else {
		httpWrite(w, 204, nil)
	}
}

func deletePesScheduleHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	id := mux.Vars(r)["id"]
	id = strings.ToLower(strings.TrimSpace(strings.Replace(id, "-", "", -1)))
	if len(id) != 32 {
		httpError(w, 400, "invalid schedule id", nil)
		return
	}
	del, e := deletePesScheduleByIdDb(mac, id)
	if e != nil {
		httpError(w, 500, fmt.Sprintf("db error for %v %v", mac, id), e)
		return
	}
	if del {
		flagScheduleDirty(mac, true)
		httpWrite(w, 200, nil)
	} else {
		httpWrite(w, 204, nil)
	}
}

func deletePesScheduleByIdDb(macAddress string, id string) (bool, error) {
	del, e := _pgCn.ExecNonQuery("DELETE FROM \"pes_schedule\" WHERE \"id\"=$1;", id)
	if e != nil {
		return false, e
	}
	affected, _ := del.RowsAffected()
	if affected > 0 {
		flagScheduleDirty(macAddress, true)
		return true, nil
	} else {
		return false, nil
	}
}

func syncPesScheduleHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	rv, err := executePesSync(mac)

	if err != nil {
		httpError(w, 500, "unable to sync schedule", err)
		return
	}

	httpWrite(w, 202, rv)
}

func executePesSync(mac string) ([]*PesHardwareDirectiveModel, error) {

	devInfo, err := getDeviceInfo(mac)
	if err != nil {
		// Check if device is unpaired.
		if !strings.Contains(err.Error(), fmt.Sprintf("api bad status code %v %v", mac, 404)) {
			return nil, errors.New(fmt.Sprintf("executePesSync: unable to retrieve device data from api. %v", err))
		}
		// Remove dirty flag for the unpaired device.
		_, e := _pgCn.ExecNonQuery("UPDATE \"pes\" SET \"schedule_dirty\"=0, \"schedule_last_sync\"=$2 WHERE \"device_id\"=$1", mac, time.Now().UTC().Truncate(time.Second))
		if e != nil {
			return nil, e
		}
		return nil, errors.New(fmt.Sprintf("executePesSync: device not found in our records. Removed dirty flag. %v", mac))
	}
	syncId, _, _ := newUuid()

	// Get the current schedule
	// Create
	schedule, err := getPesScheduleDb(mac)
	if err != nil {
		return nil, errors.New(fmt.Sprintf("unable to retrieve scheduled from data source. %v", err))
	}

	homeSch, err := syncScheduleForMode(mac, devInfo.Id, syncId, SYSTEM_MODE_HOME, schedule)
	if err != nil {
		return nil, errors.New(fmt.Sprintf("unable to send scheduled to device. %v %v %v", mac, devInfo.Id, err))
	}

	awaySch, err := syncScheduleForMode(mac, devInfo.Id, syncId, SYSTEM_MODE_AWAY, schedule)
	if err != nil {
		return nil, errors.New(fmt.Sprintf("unable to send scheduled to device. %v %v %v", mac, devInfo.Id, err))
	}

	// send directive for HOME
	_, e := _pgCn.ExecNonQuery("INSERT INTO \"pes\" (\"device_id\",\"schedule_sync_id\") VALUES ($1,$2) ON CONFLICT (device_id) DO UPDATE SET \"schedule_sync_id\"=$2", mac, syncId)
	if e != nil {
		return nil, e
	}

	return []*PesHardwareDirectiveModel{homeSch, awaySch}, nil
}

func pullPesScheduleHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	wipe := false

	if r != nil && r.URL != nil && len(r.URL.Query()) > 0 {
		x := r.URL.Query()["wipe"]
		if len(x) == 1 {
			wipe = strings.EqualFold(x[0], "true")
		}
	}

	if wipe {
		_, err := _pgCn.ExecNonQuery("DELETE FROM \"pes_schedule\" WHERE \"device_id\"=$1", mac)
		if err != nil {
			httpError(w, 500, "unable to remove records from database", err)
			return
		}
	}

	requestDevicePesSchedule(mac, SYSTEM_MODE_HOME)
	time.Sleep(time.Second)
	requestDevicePesSchedule(mac, SYSTEM_MODE_AWAY)
	time.Sleep(time.Second)

	httpWrite(w, 202, nil)
}

func syncScheduleForMode(mac string, icdId string, syncId, mode string, schedule []*PesScheduleItemModel) (*PesHardwareDirectiveModel, error) {
	env := new(PesHardwareDirectiveModel)
	env.SystemMode = mode
	env.Schedules = make([]PesSettingsHwItemModel, 0)

	for _, s := range schedule {
		if s.Mode != mode {
			continue
		}
		delta := PesSettingsHwItemModel{}
		delta.Name = s.Name
		delta.Schedule = toIcal(syncId, mac, s)
		delta.MaxDuration = s.EventLimits.Duration
		delta.MaxVolume = s.EventLimits.Volume
		delta.MaxRate = s.EventLimits.FlowRate
		delta.MaxRateDuration = s.EventLimits.getValidFlowRateDuration()

		if s.ShutoffDisabled == nil || *s.ShutoffDisabled == false {
			t := true
			delta.AutoShutOffEnabled = &t // Opposite in the FW
		} else {
			f := false
			delta.AutoShutOffEnabled = &f // Opposite in the FW
		}
		if s.ShutoffDelay == nil {
			v := DEFAULT_SHUTOFF_DELAY
			delta.AutoShutOffDelay = &v
		} else {
			d := *s.ShutoffDelay
			delta.AutoShutOffDelay = &d
		}

		env.Schedules = append(env.Schedules, delta)
	}

	err := sendScheduleDirective(icdId, env)
	if err != nil {
		return nil, logError("unable to send scheduled to device. %v %v %v %v", mac, icdId, mode, err.Error())
	}
	return env, nil
}

// Data retreived from DB is almost all from JSON blob. Columns are there for searching and reports. Updating a column
// will not update JSON blob.
func getPesScheduleDb(macAddress string) ([]*PesScheduleItemModel, error) {
	if !isValidMacAddress(macAddress) {
		return nil, logError("insertScheduleDb: invalid mac address")
	}

	rows, err := _pgCn.Query("SELECT \"data_json\",\"device_confirmed\" FROM \"pes_schedule\" WHERE \"device_id\"=$1 ORDER BY \"mode\",\"order\",\"start_minute\";", macAddress)
	if err != nil {
		return nil, logError("getPesScheduleDb: %v", err.Error())
	}
	defer rows.Close()

	rv := make([]*PesScheduleItemModel, 0)
	for rows.Next() {
		jsonString := ""
		devConfirmed := 0
		err = rows.Scan(&jsonString, &devConfirmed)

		if err != nil {
			logWarn("getPesScheduleDb: error scanning row for %v. %v", macAddress, err.Error())
			continue
		}
		delta := new(PesScheduleItemModel)
		err = json.Unmarshal([]byte(jsonString), &delta)
		if err != nil {
			logWarn("getPesScheduleDb: error deserializing json %v. %v", macAddress, err.Error())
			continue
		}

		delta.ICalString = toIcal("", macAddress, delta)
		delta.DeviceConfirmed = devConfirmed > 0
		rv = append(rv, delta)
	}

	return rv, nil
}

func getOverrideSchedulesDb(macAddress string) ([]*PesScheduleItemModel, error) {

	s, e := getPesScheduleDb(macAddress)
	if e != nil {
		return s, e
	}

	if len(s) == 0 {
		return s, e
	}

	rv := make([]*PesScheduleItemModel, 0)
	for _, i := range s {
		if isScheduleItemAnOverride(i) {
			rv = append(rv, i)
		}
	}

	return rv, nil
}

func isScheduleItemAnOverride(item *PesScheduleItemModel) bool {
	if item == nil {
		return false
	}

	return item.Order == 100 && strings.EqualFold(item.Name, "FloSenseOverride")
}

func toIcal(syncId string, macAddress string, item *PesScheduleItemModel) string {
	if item == nil {
		return ""
	}

	tz, _ := getDeviceInfo(macAddress)
	loc, _ := time.LoadLocation(tz.Location.Timezone)
	now := time.Now().Format("2006-01-02")
	userTime, _ := time.ParseInLocation("2006-01-02", now, loc)

	startMinutes := parseTimeString(item.StartTime)
	endMinutes := parseTimeString(item.EndTime)
	userStart := userTime.Add(time.Duration(startMinutes) * time.Minute)
	userEnd := userTime.Add(time.Duration(endMinutes) * time.Minute)

	if startMinutes > endMinutes {
		userEnd = userEnd.Add(24 * time.Hour)
	}

	utcStart := userStart.UTC()
	utcEnd := userEnd.UTC()

	cal := ics.NewCalendar()

	if len(syncId) == 0 {
		syncId = "none"
	}

	cal.SetProductId("flo-science-lab@meetflo.com")
	event := cal.AddEvent(fmt.Sprintf("pes:%v.%v", item.Id, syncId))
	event.SetDtStampTime(time.Now().UTC())
	event.SetStartAt(utcStart)
	event.SetEndAt(utcEnd)

	isShiftedOneDay := userStart.Day() != utcStart.Day()
	days := make([]string, 0)
	if item.Repeat.Daily.Monday {
		days = append(days, getValueIfElse("MO", "TU", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Tuesday {
		days = append(days, getValueIfElse("TU", "WE", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Wednesday {
		days = append(days, getValueIfElse("WE", "TH", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Thursday {
		days = append(days, getValueIfElse("TH", "FR", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Friday {
		days = append(days, getValueIfElse("FR", "SA", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Saturday {
		days = append(days, getValueIfElse("SA", "SU", !isShiftedOneDay))
	}
	if item.Repeat.Daily.Sunday {
		days = append(days, getValueIfElse("SU", "MO", !isShiftedOneDay))
	}

	// No days means all days
	if len(days) == 0 {
		days = []string{"MO", "TU", "WE", "TH", "FR", "SA", "SU"}
	}

	event.SetRepeatDailyRule(days)

	return cal.Serialize()
}

func getValueIfElse(x string, y string, condition bool) string {
	if condition {
		return x
	} else {
		return y
	}
}

func getPesDataDb(macAddress string) (*PesDataDAL, error) {
	if !isValidMacAddress(macAddress) {
		return nil, logError("getPesDataDb: invalid mac address")
	}

	rows, err := _pgCn.Query("SELECT \"device_id\",\"schedule_dirty\",\"schedule_last_sync\" FROM \"pes\" WHERE \"device_id\"=$1;", macAddress)
	if err != nil {
		return nil, logError("getPesScheduleDb: %v", err.Error())
	}
	defer rows.Close()

	if rows.Next() {
		rv := new(PesDataDAL)
		err = rows.Scan(&rv.MacAddress, &rv.ScheduleDirty, &rv.ScheduleLastSent)
		return rv, nil
	}
	return nil, nil
}

func flagScheduleDirty(macAddress string, isDirty bool) error {
	if !isValidMacAddress(macAddress) {
		return logError("insertScheduleDb: invalid mac address")
	}

	dirtyNum := 0
	if isDirty {
		dirtyNum = 1
	}

	_, err := _pgCn.ExecNonQuery("INSERT INTO \"pes\" (\"device_id\",\"schedule_dirty\") VALUES ($1,$2) "+
		" ON CONFLICT (device_id) DO UPDATE SET \"schedule_dirty\"=$2", macAddress, dirtyNum)
	if err != nil {
		return logError("flagScheduleDirty: %v %v", macAddress, err.Error())
	}
	return nil
}

func insertScheduleDb(macAddress string, item *PesScheduleItemModel, suppressErrors bool) (*PesScheduleItemModel, error) {
	if !isValidMacAddress(macAddress) {
		return nil, logError("insertScheduleDb: invalid mac address")
	}
	if item == nil {
		return nil, logError("insertScheduleDb: item nil")
	}

	if len(item.Id) != 32 {
		item.Id, _, _ = newUuid()
	}

	if item.Created.Year() < 2000 {
		item.Created = time.Now().UTC().Truncate(time.Second)
	}

	jsonData, e := json.Marshal(item)
	if e != nil {
		return nil, logError("insertScheduleDb: json serializer error. %v %v", macAddress, e.Error())
	}

	tStart := parseTimeString(item.StartTime)
	tEnd := parseTimeString(item.EndTime)

	_, err := _pgCn.ExecNonQuery("INSERT INTO \"pes_schedule\" "+
		" (\"id\",\"device_id\",\"mode\",\"order\",\"name\",\"created_at\",\"updated_at\",\"data_json\",\"start_minute\",\"end_minute\") "+
		"VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);",
		item.Id,
		macAddress,
		item.Mode,
		item.Order,
		item.Name,
		item.Created,
		item.Created,
		string(jsonData),
		tStart,
		tEnd,
	)
	if err != nil {
		if suppressErrors {
			return nil, nil
		}
		return nil, logError("insertScheduleDb: unable to save schedule for %v. %v", macAddress, err.Error())
	}
	logDebug("insertScheduleDb: new schedule %v %v", macAddress, string(jsonData))

	flagScheduleDirty(macAddress, true)

	return item, nil
}
func updateScheduleDb(macAddress string, item *PesScheduleItemModel) (bool, error) {
	if !isValidMacAddress(macAddress) {
		return false, logError("updateScheduleDb: invalid mac address")
	}
	if item == nil {
		return false, logError("updateScheduleDb: item nil")
	}

	if len(item.Id) != 32 {
		return false, logError("updateScheduleDb: id property is empty")
	}

	jsonData, e := json.Marshal(item)
	if e != nil {
		return false, logError("updateScheduleDb: json serializer error. %v %v", macAddress, e.Error())
	}

	item.ICalString = ""
	item.DeviceConfirmed = false
	tStart := parseTimeString(item.StartTime)
	tEnd := parseTimeString(item.EndTime)

	affected, err := _pgCn.ExecNonQuery("UPDATE \"pes_schedule\" SET "+
		"\"name\"=$2,\"mode\"=$3,\"order\"=$4,\"updated_at\"=$5,\"data_json\"=$6,\"start_minute\"=$7,\"end_minute\"=$8 "+
		"WHERE \"id\"=$1",
		item.Id,
		item.Name,
		item.Mode,
		item.Order,
		time.Now().UTC().Truncate(time.Second),
		string(jsonData),
		tStart,
		tEnd,
	)

	if err != nil {
		return false, logError("updateScheduleDb: unable to save schedule for %v. %v", macAddress, err.Error())
	}

	rowCount, _ := affected.RowsAffected()

	if rowCount > 0 {
		flagScheduleDirty(macAddress, true)
		logDebug("updateScheduleDb: updated schedule %v %v", item.Id, macAddress)
		return true, nil
	} else {
		logWarn("updateScheduleDb: not found %v %v", item.Id, macAddress)
		return false, nil
	}
}

func parseScheduleModel(r *http.Request) (*PesScheduleItemModel, error) {
	if r == nil {
		return nil, logError("nil request")
	}
	if r.Body == nil {
		return nil, logError("nil body")
	}

	b, e := ioutil.ReadAll(r.Body)
	if e != nil {
		return nil, logError("error reading body. %v", e.Error())
	}
	defer r.Body.Close()
	if len(b) <= 2 {
		return nil, logError("body is too short for json")
	}

	rv := new(PesScheduleItemModel)
	e = json.Unmarshal(b, &rv)
	if e != nil {
		return nil, logError("error deserialize json %v", e.Error())
	}

	return rv, nil
}

func initPesDirectiveWorker() {
	kafka, _ := OpenKafka(_kafkaCn)
	topics := []string{"directives-response-v2"}

	if kafka == nil {
		logError("initPesDirectiveWorker: Can't continue, exiting")
		os.Exit(-20)
	}

	_, err := kafka.Subscribe(_kafkaGroupId, topics, processDirectiveWorker)

	if err != nil {
		logError("initPesDirectiveWorker: Can't subscribe to topics, exiting. %v", topics)
		os.Exit(-20)
	}
}

func processDirectiveWorker(item *kafka.Message) {
	if item == nil || len(item.Value) == 0 {
		return
	}

	dir := DirectiveBaseEnvelope{}
	err := json.Unmarshal(item.Value, &dir)
	if err != nil {
		logError("processDirectiveWorker: %v %v", err.Error(), string(item.Value))
		return
	}
	if !isValidMacAddress(dir.DeviceId) {
		logError("processDirectiveWorker: invalid mac address %v", dir.DeviceId)
		return
	}

	switch dir.Directive {
	case "set-pes-schedule":
		go func(mac string) {
			// Wait few seconds before sending request
			time.Sleep(time.Second * 5)
			requestDevicePesSchedule(mac, SYSTEM_MODE_HOME)
			time.Sleep(time.Second)
			requestDevicePesSchedule(mac, SYSTEM_MODE_AWAY)
		}(dir.DeviceId)
	case "get-pes-schedule":
		dir := DirectiveResponseEnvelope{}
		err := json.Unmarshal(item.Value, &dir)
		if err != nil {
			logError("processDirectiveWorker: %v %v", err.Error(), string(item.Value))
			return
		}
		if !isValidMacAddress(dir.DeviceId) {
			logError("processDirectiveWorker: invalid mac address %v", dir.DeviceId)
			return
		}
		processGetSchedule(dir)
	}
}

func processGetSchedule(item DirectiveResponseEnvelope) error {
	if !strings.EqualFold(item.Directive, "get-pes-schedule") {
		return nil
	}
	if item.Data == nil || len(item.Data) == 0 {
		return logError("processGetSchedule: bad input")
	}

	tmp, err := json.Marshal(item.Data)
	if err != nil {
		return logError("processGetSchedule: unable to serialize data. %v", err.Error())

	}

	sch := PesHardwareDirectiveModel{}
	err = json.Unmarshal(tmp, &sch)
	if err != nil {
		return logError("processGetSchedule: unable to unmarshal schedule data. %v", err.Error())
	}

	if len(sch.Schedules) == 0 {
		_, err = _pgCn.ExecNonQuery("UPDATE \"pes\" SET \"schedule_dirty\"=0, \"schedule_last_sync\"=$2 WHERE \"device_id\"=$1", item.DeviceId, time.Now().UTC().Truncate(time.Second))
		if err != nil {
			logError("processGetSchedule: error updating pes record in db: %v %v", item.DeviceId, err.Error())
		}
		return nil
	}

	logDebug("processGetSchedule: Processing %v %v", item.DeviceId, sch.SystemMode)

	syncList := make(map[string]bool)
	orderIndex := -100
	for _, s := range sch.Schedules {
		if len(s.Schedule) == 0 {
			continue
		}
		orderIndex++

		delta, err := ics.ParseCalendar(bytes.NewBufferString(s.Schedule))

		if err != nil {
			logWarn("processGetSchedule: unable to parse calendar. %v %v", s.Schedule, err.Error())
			continue
		}

		for _, ev := range delta.Events() {
			if ev == nil {
				continue
			}

			schId := ev.Id()
			if !strings.HasPrefix(schId, "pes:") {
				processLegacySchedule(item, sch, s, orderIndex, ev, "")
				logDebug("processGetSchedule: LEGACY SCHEDULE")
				continue
			}

			parts := strings.Split(schId[4:], ".")
			if len(parts) < 2 {
				continue
			}
			if len(parts[0]) < 32 {
				continue
			}

			syncList[parts[1]] = true

			logDebug("processGetSchedule: CONFIRMING SCHEDULE %v %v", parts[0], parts[1])

			x, err := _pgCn.ExecNonQuery("UPDATE \"pes_schedule\" SET \"device_confirmed\"=1,\"updated_at\"=$2 WHERE \"id\"=$1", parts[0], time.Now().UTC())
			if err != nil {
				logError("processGetSchedule: error updating record in db: %v %v", item.DeviceId, err.Error())
				continue
			}
			affected, _ := x.RowsAffected()
			if affected == 0 {
				logWarn("processGetSchedule: RECOVERING SCHEDULE")
				processLegacySchedule(item, sch, s, orderIndex, ev, parts[0])
			}
		}
	}

	for k, _ := range syncList {
		_pgCn.ExecNonQuery("UPDATE \"pes\" SET \"schedule_dirty\"=0, \"schedule_last_sync\"=$2 WHERE \"schedule_sync_id\"=$1", k, time.Now().UTC().Truncate(time.Second))
	}

	return nil
}

func processLegacySchedule(directive DirectiveResponseEnvelope, pes PesHardwareDirectiveModel, scheduleItem PesSettingsHwItemModel, order int, event *ics.VEvent, scheduleId string) {
	delta := PesScheduleItemModel{}

	if len(scheduleId) >= 32 {
		delta.Id = strings.Replace(strings.ToLower(scheduleId), "-", "", -1)
	} else {
		delta.Id, _, _ = newUuid()
	}

	delta.Name = scheduleItem.Name
	delta.Mode = pes.SystemMode
	delta.Order = order

	if scheduleItem.AutoShutOffDelay == nil {
		v := DEFAULT_SHUTOFF_DELAY
		delta.ShutoffDelay = &v
	} else {
		v := *scheduleItem.AutoShutOffDelay
		delta.ShutoffDelay = &v
	}

	if scheduleItem.AutoShutOffEnabled == nil || *scheduleItem.AutoShutOffEnabled {
		f := false
		delta.ShutoffDisabled = &f
	} else {
		t := true
		delta.ShutoffDisabled = &t
	}

	delta.EventLimits.Volume = scheduleItem.MaxVolume
	delta.EventLimits.Duration = scheduleItem.MaxDuration
	delta.EventLimits.FlowRate = scheduleItem.MaxRate
	delta.EventLimits.FlowRateDuration = scheduleItem.MaxRateDuration

	delta.Created = time.Now().UTC().Truncate(time.Second)

	// Don't judge me, need it done
	rrule := event.GetProperty(ics.ComponentRepeatRule)
	if rrule != nil && len(rrule.Value) > 0 {
		if strings.EqualFold(rrule.Value, "FREQ=DAILY;INTERVAL=1") {
			delta.Repeat.Daily.Sunday = true
			delta.Repeat.Daily.Monday = true
			delta.Repeat.Daily.Tuesday = true
			delta.Repeat.Daily.Wednesday = true
			delta.Repeat.Daily.Thursday = true
			delta.Repeat.Daily.Friday = true
			delta.Repeat.Daily.Saturday = true
		} else if len(rrule.Value) > 16 && strings.HasPrefix(rrule.Value, "FREQ=DAILY;BYDAY=") {
			days := rrule.Value[17:]
			if strings.Contains(days, "SU") {
				delta.Repeat.Daily.Sunday = true
			}
			if strings.Contains(days, "MO") {
				delta.Repeat.Daily.Monday = true
			}
			if strings.Contains(days, "TU") {
				delta.Repeat.Daily.Tuesday = true
			}
			if strings.Contains(days, "WE") {
				delta.Repeat.Daily.Wednesday = true
			}
			if strings.Contains(days, "TH") {
				delta.Repeat.Daily.Thursday = true
			}
			if strings.Contains(days, "FR") {
				delta.Repeat.Daily.Friday = true
			}
			if strings.Contains(days, "SA") {
				delta.Repeat.Daily.Saturday = true
			}
		}
	}

	devInfo, e := getDeviceInfo(directive.DeviceId)
	if e != nil {
		logWarn("processLegacySchedule: can't get device info. %v %v", directive.DeviceId, e.Error())
		return
	}
	loc, _ := time.LoadLocation(devInfo.Location.Timezone)

	delta.StartTime = parseICalTimeToLocalTime(directive.DeviceId, event.GetProperty(ics.ComponentPropertyDtStart), loc)
	delta.EndTime = parseICalTimeToLocalTime(directive.DeviceId, event.GetProperty(ics.ComponentPropertyDtEnd), loc)

	logDebug("Legacy Schedule: %v", tryToJson(delta))

	// Insert data - don't worry about errors
	insertScheduleDb(directive.DeviceId, &delta, true)
}

func parseICalTimeToLocalTime(mac string, icalTime *ics.IANAProperty, loc *time.Location) string {
	if icalTime == nil || len(icalTime.Value) < 12 {
		logWarn("parseTimeToLocal: ical missing DTSTART, returning 00:00. %v", mac)
		return "00:00"
	}

	utcTime, e := time.Parse("20060102T150405Z", icalTime.Value)
	if e != nil {
		logWarn("parseTimeToLocal: can't parse legacy icalTime time format. %v %v", mac, icalTime.Value)
		return "00:00"
	}

	if loc == nil {
		return utcTime.Format("15:04")
	}

	localTime := utcTime.In(loc)

	return localTime.Format("15:04")
}

func requestDevicePesSchedule(macAddress string, systemMode string) {
	if !isValidMacAddress(macAddress) {
		logError("queueGetPesSchedule: invalid mac address %v", macAddress)
		return
	}

	// Get device info
	dev, err := getDeviceInfo(macAddress)
	if err != nil {
		logError("queueGetPesSchedule: unable to get device info %v %v", macAddress, err.Error())
		return
	}

	// Queue the request
	err = sendDirective(dev.Id, "getpesschedule", []byte(tryToJson(map[string]interface{}{"sm": systemMode})))
	if err != nil {
		logError("queueGetPesSchedule: unable to queue get schedule info %v %v", macAddress, err.Error())
		return
	}
	logDebug("queueGetPesSchedule: request schedule for %v %v", macAddress, systemMode)
}

func initPesScheduleRetryJob() (func(), error) {
	fdCron := cron.New(cron.WithLocation(time.UTC))

	_, err := fdCron.AddFunc(_pesScheduleRetryCron, pesSchedulerRetryWorker)
	if err != nil {
		return nil, err
	}

	fdCron.Start()

	stop := func() {
		fdCron.Stop()
	}

	return stop, nil
}

func pesSchedulerRetryWorker() {
	logInfo("pesScheduleRetryWorker: Starting pes retry loop")
	start := time.Now()

	rows, err := _pgCn.Query("SELECT \"device_id\" FROM \"pes\" "+
		"WHERE \"schedule_dirty\"=1 ORDER BY random() LIMIT $1;", _pesScheduleRetryBatchSize)
	if err != nil {
		logError("pesSchedulerRetryWorker: error fetching dirty devices to retry %v", err.Error())
	}
	defer rows.Close()

	count := 0
	total := 0
	for rows.Next() {
		total++
		macAddress := ""
		err = rows.Scan(&macAddress)

		if err != nil {
			logWarn("pesSchedulerRetryWorker: error scanning pes row. %v", err.Error())
			continue
		}

		key := fmt.Sprintf("mutex:pesSchedule:syncRetry:%v", macAddress)
		result, _ := _redis.SetNX(key, true, 30*60)
		if !result {
			continue
		}

		logDebug("pesSchedulerRetryWorker: Starting Sync process for macAddress. %v", macAddress)
		count++
		_, err = executePesSync(macAddress)
		if err != nil {
			logError("pesSchedulerRetryWorker: error processing executePesSync. %v", err.Error())
			continue
		}
	}
	logInfo("pesSchedulerRetryWorker: Completed retry loop for %v/%v devices in %.3f seconds",
		count, total, time.Now().Sub(start).Seconds())
}
