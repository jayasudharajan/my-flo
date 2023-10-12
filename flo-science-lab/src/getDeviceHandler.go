package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

var _currentLevels []FloSenseLevelModel
var _defaultFloSenseRecord FloSenseDal
var _defaultPesValues PesThresholdModel

func init() {
	_currentLevels = []FloSenseLevelModel{
		FloSenseLevelModel{Level: 5, FloProtectCoverage: true, Default: false, DisplayName: "Ok", DisplayOrder: 1},
		FloSenseLevelModel{Level: 4, FloProtectCoverage: true, Default: false, DisplayName: "Good", DisplayOrder: 2},
		FloSenseLevelModel{Level: 3, FloProtectCoverage: true, Default: false, DisplayName: "Better", DisplayOrder: 3},
		FloSenseLevelModel{Level: 2, FloProtectCoverage: true, Default: true, DisplayName: "Best", DisplayOrder: 4},
		FloSenseLevelModel{Level: 1, FloProtectCoverage: true, Default: false, DisplayName: "Super", DisplayOrder: 5},
	}
	_defaultFloSenseRecord = FloSenseDal{DeviceLevel: 2, UserEnabled: 1}

	_defaultPesValues.FlowRate.Step = 0.1
	_defaultPesValues.FlowRate.Min = 0.1
	_defaultPesValues.FlowRate.Max = 25
	_defaultPesValues.FlowRate.Value = 0.1

	_defaultPesValues.FlowRateDuration.Step = 1
	_defaultPesValues.FlowRateDuration.Min = 1
	_defaultPesValues.FlowRateDuration.Max = 60
	_defaultPesValues.FlowRateDuration.Value = 1

	_defaultPesValues.EventDuration.Step = 60
	_defaultPesValues.EventDuration.Min = 60
	_defaultPesValues.EventDuration.Max = 7200
	_defaultPesValues.EventDuration.Value = 1

	_defaultPesValues.EventVolume.Step = 1
	_defaultPesValues.EventVolume.Min = 1
	_defaultPesValues.EventVolume.Max = 1000
	_defaultPesValues.EventVolume.Value = 1
}

type UpdateDevicePostModel struct {
	MacAddress string               `json:"macAddress"`
	FloSense   *UpdateFlosenseModel `json:"floSense"`
}

type UpdateFlosenseModel struct {
	ShutoffLevel *int                   `json:"shutoffLevel"`
	UserEnabled  *bool                  `json:"userEnabled"`
	PesOverride  *FloSenseOverrideModel `json:"pesOverride"`
}

type DeviceInfoModel struct {
	MacAddress string        `json:"macAddress"`
	FloSense   FloSenseModel `json:"floSense"`
	PES        PESModel      `json:"pes"`
}

type FloSenseModel struct {
	ShutoffLevel    int                    `json:"shutoffLevel"`
	UserEnabled     bool                   `json:"userEnabled"`
	PesOverride     *FloSenseOverrideModel `json:"pesOverride"`
	AvailableLevels []FloSenseLevelModel   `json:"availableLevels"`
}

type FloSenseOverrideModel struct {
	Home *PesScheduleItemModel `json:"home"`
	Away *PesScheduleItemModel `json:"away"`
}

type FloSenseLevelModel struct {
	Level              int    `json:"level,omitempty"`
	DisplayName        string `json:"displayName,omitempty"`
	FloProtectCoverage bool   `json:"floProtectCoverage,omitempty"`
	Default            bool   `json:"default,omitempty"`
	DisplayOrder       int    `json:"displayOrder,omitempty"`
}

type PESModel struct {
	Schedule PesScheduleModel `json:"schedule"`
}

type PesThresholdModel struct {
	FlowRate         PesThresholdItemModel `json:"flowRate"`
	FlowRateDuration PesThresholdItemModel `json:"flowRateDuration"`
	EventDuration    PesThresholdItemModel `json:"eventDuration"`
	EventVolume      PesThresholdItemModel `json:"eventVolume"`
}

type PesThresholdItemModel struct {
	Step  float64 `json:"step"`
	Min   float64 `json:"min"`
	Max   float64 `json:"max"`
	Value float64 `json:"value"`
}

type PesScheduleModel struct {
	SyncRequired bool                    `json:"syncRequired"`
	LastSync     time.Time               `json:"lastSync"`
	Defaults     PesThresholdModel       `json:"defaults"`
	Items        []*PesScheduleItemModel `json:"items"`
}

type PesScheduleItemModel struct {
	Id              string              `json:"id"` // uuid
	Name            string              `json:"name"`
	Mode            string              `json:"mode"`
	StartTime       string              `json:"startTime"`
	EndTime         string              `json:"endTime"`
	Repeat          RepeatEnvelopeModel `json:"repeat"`
	EventLimits     PesEventLimitsModel `json:"eventLimits"`
	ShutoffDisabled *bool               `json:"shutoffDisabled"`
	ShutoffDelay    *int                `json:"shutoffDelay"` // secs
	Order           int                 `json:"order"`
	Created         time.Time           `json:"created"`
	ICalString      string              `json:"iCalString"`
	DeviceConfirmed bool                `json:"deviceConfirmed"`
}

type PesEventLimitsModel struct {
	Duration         float32 `json:"duration"`         // max_duration
	Volume           float32 `json:"volume"`           // max_volume
	FlowRate         float32 `json:"flowRate"`         // max_rate
	FlowRateDuration float32 `json:"flowRateDuration"` // max_rate_duration
}

const PES_LIMITS_MIN_FLOW_RATE = 1

// endpoint was released without validation hence why it has to be done this way
func (m PesEventLimitsModel) getValidFlowRateDuration() float32 {
	if m.FlowRateDuration < PES_LIMITS_MIN_FLOW_RATE {
		return PES_LIMITS_MIN_FLOW_RATE
	}

	return m.FlowRateDuration
}

type RepeatEnvelopeModel struct {
	Daily DaysOfWeek `json:"daily"`
}

type DaysOfWeek struct {
	Monday    bool `json:"monday"`
	Tuesday   bool `json:"tuesday"`
	Wednesday bool `json:"wednesday"`
	Thursday  bool `json:"thursday"`
	Friday    bool `json:"friday"`
	Saturday  bool `json:"saturday"`
	Sunday    bool `json:"sunday"`
}

func getDeviceHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	// Get current value from DB
	flosenseDb, err := getOrCreateFromDb(mac)
	if err != nil {
		httpError(w, 500, "database error", err)
		return
	}

	rv := DeviceInfoModel{}
	rv.MacAddress = mac
	rv.FloSense.UserEnabled = flosenseDb.UserEnabled > 0
	rv.FloSense.ShutoffLevel = flosenseDb.DeviceLevel
	rv.FloSense.AvailableLevels = _currentLevels

	// PES
	data, _ := getPesDataDb(mac)
	if data != nil {
		rv.PES.Schedule.SyncRequired = data.ScheduleDirty > 0
		rv.PES.Schedule.LastSync = data.ScheduleLastSent
	}
	rv.PES.Schedule.Items, _ = getPesScheduleDb(mac)
	rv.PES.Schedule.Defaults = _defaultPesValues

	// Look at the override
	findOveerride(&rv)

	httpWrite(w, 200, rv)
}

func findOveerride(item *DeviceInfoModel) {
	if item == nil {
		return
	}

	if len(item.PES.Schedule.Items) == 0 {
		return
	}

	delta := FloSenseOverrideModel{}

	for _, s := range item.PES.Schedule.Items {
		if isScheduleItemAnOverride(s) {
			switch s.Mode {
			case "home":
				delta.Home = s
			case "away":
				delta.Away = s
			}
		}
	}

	if delta.Home == nil && delta.Away == nil {
		return
	}

	item.FloSense.PesOverride = &delta
}

func postDeviceHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	updateModel, err := parseUpdateModel(r)
	if err != nil {
		httpError(w, 400, "input body", err)
		return
	}
	if updateModel == nil {
		httpError(w, 500, "input item nil", nil)
		return
	}
	if !strings.EqualFold(mac, updateModel.MacAddress) {
		httpError(w, 400, "url and body mac address mismatch", nil)
		return
	}

	// Get current value from DB
	flosenseDb, err := getOrCreateFromDb(mac)
	if err != nil {
		httpError(w, 500, "database error", err)
		return
	}

	change := false

	if updateModel.FloSense != nil {
		if updateModel.FloSense.UserEnabled != nil {
			change = true
			if *updateModel.FloSense.UserEnabled {
				flosenseDb.UserEnabled = 1
			} else {
				flosenseDb.UserEnabled = 0
			}
		}

		if updateModel.FloSense.ShutoffLevel != nil {
			change = true
			flosenseDb.DeviceLevel = *updateModel.FloSense.ShutoffLevel
		}
	}

	if change {
		rowsUpdated, err := upsertFloSenseSettings(flosenseDb.MacAddress, flosenseDb.UserEnabled, flosenseDb.DeviceLevel)

		if err != nil {
			httpError(w, 500, fmt.Sprintf("unable to update record %v", mac), err)
			return
		}

		updatePesOverride(flosenseDb.MacAddress, flosenseDb.UserEnabled > 0, updateModel)

		if rowsUpdated {
			// Queue the DSS to send properties to device
			sendFwProperties(flosenseDb.MacAddress, flosenseDb.DeviceLevel)
		}
	}

	httpWrite(w, 200, nil)
}

func updatePesOverride(macAddress string, userEnabled bool, item *UpdateDevicePostModel) {
	if !isValidMacAddress(macAddress) || item == nil || item.FloSense == nil || item.FloSense.PesOverride == nil {
		return
	}

	// Remove existing override
	items, _ := getOverrideSchedulesDb(macAddress)
	if len(items) > 0 {
		for _, i := range items {
			deletePesScheduleByIdDb(macAddress, i.Id)
		}
	}

	// User enabled flosense, we don't need any override information
	if userEnabled {
		return
	}

	if item.FloSense.PesOverride.Home != nil {
		h := item.FloSense.PesOverride.Home
		h.Name = "FloSenseOverride"
		h.Order = 100
		h.Mode = "home"
		h.StartTime = "00:00"
		h.EndTime = "00:00"
		h.Repeat.Daily.Monday = true
		h.Repeat.Daily.Tuesday = true
		h.Repeat.Daily.Wednesday = true
		h.Repeat.Daily.Thursday = true
		h.Repeat.Daily.Friday = true
		h.Repeat.Daily.Saturday = true
		h.Repeat.Daily.Sunday = true

		// Fix time input
		h.StartTime = parseTimeMinuteMilitary(parseTimeString(h.StartTime))
		h.EndTime = parseTimeMinuteMilitary(parseTimeString(h.EndTime))

		if h.ShutoffDelay == nil {
			sec := DEFAULT_SHUTOFF_DELAY
			h.ShutoffDelay = &sec // Default number of seconds before shutoff
		}
		if *h.ShutoffDelay < 0 || *h.ShutoffDelay > 3600 {
			return
		}
		if h.ShutoffDisabled == nil {
			f := false
			h.ShutoffDisabled = &f
		}

		insertScheduleDb(macAddress, h, false)
	}

	if item.FloSense.PesOverride.Away != nil {
		h := item.FloSense.PesOverride.Away
		h.Name = "FloSenseOverride"
		h.Order = 100
		h.Mode = "away"
		h.StartTime = "00:00"
		h.EndTime = "00:00"
		h.Repeat.Daily.Monday = true
		h.Repeat.Daily.Tuesday = true
		h.Repeat.Daily.Wednesday = true
		h.Repeat.Daily.Thursday = true
		h.Repeat.Daily.Friday = true
		h.Repeat.Daily.Saturday = true
		h.Repeat.Daily.Sunday = true

		// Fix time input
		h.StartTime = parseTimeMinuteMilitary(parseTimeString(h.StartTime))
		h.EndTime = parseTimeMinuteMilitary(parseTimeString(h.EndTime))

		if h.ShutoffDelay == nil {
			sec := DEFAULT_SHUTOFF_DELAY
			h.ShutoffDelay = &sec // Default number of seconds before shutoff
		}
		if *h.ShutoffDelay < 0 || *h.ShutoffDelay > 3600 {
			return
		}
		if h.ShutoffDisabled == nil {
			f := false
			h.ShutoffDisabled = &f
		}

		insertScheduleDb(macAddress, h, false)
	}

	executePesSync(macAddress)
}

func deleteDeviceHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	_pgCn.ExecNonQuery("DELETE FROM \"pes\" WHERE \"device_id\"=$1", mac)
	_pgCn.ExecNonQuery("DELETE FROM \"pes_schedule\" WHERE \"device_id\"=$1", mac)
	_pgCn.ExecNonQuery("DELETE FROM \"flosense\" WHERE \"device_id\"=$1", mac)
}

type FloSenseDal struct {
	MacAddress          string
	UserEnabled         int
	DeviceLevel         int
	ReLearningExpiresAt time.Time
	ReLearningEnabled   int
}

func parseUpdateModel(r *http.Request) (*UpdateDevicePostModel, error) {
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

	rv := new(UpdateDevicePostModel)
	e = json.Unmarshal(b, &rv)
	if e != nil {
		return nil, logError("error deserialize json %v", e.Error())
	}

	return rv, nil
}

func getOrCreateFromDb(macAddress string) (*FloSenseDal, error) {
	// Get current value from DB
	flosenseDb, err := getFloSenseFromDb(macAddress)
	if err != nil {
		return nil, err
	}

	if flosenseDb == nil {
		flosenseDb = &FloSenseDal{
			MacAddress:  macAddress,
			DeviceLevel: _defaultFloSenseRecord.DeviceLevel,
			UserEnabled: _defaultFloSenseRecord.UserEnabled}

		_, err = upsertFloSenseSettings(flosenseDb.MacAddress, flosenseDb.UserEnabled, flosenseDb.DeviceLevel)
	}

	return flosenseDb, err
}

func upsertFloSenseSettings(macAddress string, userEnabled int, deviceLevel int) (bool, error) {
	macAddress = strings.TrimSpace(strings.ToLower(macAddress))

	if !isValidMacAddress(macAddress) {
		return false, logError("upsertFloSenseSettings: bad mac address format. %v", macAddress)
	}

	if userEnabled > 0 {
		userEnabled = 1
	} else {
		userEnabled = 0
	}

	changed := int64(0)

	result, err := _pgCn.ExecNonQuery("INSERT INTO flosense (device_id,user_enabled,device_level) "+
		"VALUES ($1,$2,$3) ON CONFLICT (device_id) DO NOTHING;",
		macAddress,
		userEnabled,
		deviceLevel)

	if err != nil {
		logWarn("upsertFloSenseSettings: failed to insert. %v %v %v %v", macAddress, userEnabled, deviceLevel, err.Error())
	} else {
		affected, _ := result.RowsAffected()
		changed += affected
	}

	if changed == 0 {
		result, err := _pgCn.ExecNonQuery("UPDATE flosense SET user_enabled=$2,device_level=$3 WHERE device_id=$1 AND (user_enabled != $2 OR device_level != $3);",
			macAddress,
			userEnabled,
			deviceLevel)

		if err != nil {
			logWarn("upsertFloSenseSettings: failed to update. %v %v %v %v", macAddress, userEnabled, deviceLevel, err.Error())
		} else {
			affected, _ := result.RowsAffected()
			changed += affected
		}
	}

	if changed > 0 {
		_, err := _pgCn.ExecNonQuery("INSERT INTO \"flosense_history\" (\"date\",\"device_id\",\"user_enabled\",\"device_level\") "+
			" VALUES ($1,$2,$3,$4) ON CONFLICT (date, device_id) DO UPDATE SET \"user_enabled\"=$3,\"device_level\"=$4;",
			time.Now().UTC(),
			macAddress,
			userEnabled,
			deviceLevel,
		)

		if err != nil {
			logWarn("upsertFloSenseSettings: failed to write history. %v %v %v %v", macAddress, userEnabled, deviceLevel, err.Error())
		}
	}

	return changed > 0, err
}

func getFloSenseFromDb(macAddress string) (*FloSenseDal, error) {
	if _pgCn == nil {
		return nil, logError("getFloSenseFromDb: nil pgCn")
	}

	if !isValidMacAddress(macAddress) {
		return nil, logError("getFloSenseFromDb: invalid mac address: %v", macAddress)
	}

	rows, err := _pgCn.Query("SELECT device_id,user_enabled,device_level,relearning_expires_at,relearning_enabled FROM flosense WHERE device_id=$1", macAddress)
	if err != nil {
		return nil, logError("getFloSenseFromDb: SELECT %v %v", macAddress, err.Error())
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, nil
	}

	rv := new(FloSenseDal)

	err = rows.Scan(&rv.MacAddress, &rv.UserEnabled, &rv.DeviceLevel, &rv.ReLearningExpiresAt, &rv.ReLearningEnabled)
	if err != nil {
		return nil, logError("getFloSenseFromDb: SCAN %v %v", macAddress, err.Error())
	}

	return rv, nil
}
