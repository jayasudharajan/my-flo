package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/blang/semver"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/gorilla/mux"
)

const KAFKA_DEVICE_PROPERTIES_TOPIC string = "device-properties-pub-v1"
const FWPROP_FLOSENSE_SHUTOFF_LEVEL string = "flosense_shut_off_level"
const FWPROP_FLOSENSE_LINK string = "flosense_link"
const MAX_CONCURRENT_MODEL_POST int64 = 10

const (
	MODEL_STATUS_EXPIRED   int = -3  // Could not deliver the deployment in time
	MODEL_STATUS_CANCELLED int = -2  // Deployment deleted before being deployed
	MODEL_STATUS_ERROR     int = -1  // Something went wrong
	MODEL_STATUS_QUEUED    int = 0   // Client provided data, need to validate and process the file
	MODEL_STATUS_READY     int = 20  // Cloud is ready to deliver the file to FW
	MODEL_STATUS_PENDINGFW int = 90  // Device downloaded and is pending activation
	MODEL_STATUS_DEPLOYED  int = 100 // Device confirmed it is currently running this version
)

var ModelStatusLookup = map[int]string{
	MODEL_STATUS_ERROR:     "error",
	MODEL_STATUS_QUEUED:    "queued",
	MODEL_STATUS_READY:     "ready",
	MODEL_STATUS_PENDINGFW: "pendingfw",
	MODEL_STATUS_DEPLOYED:  "deployed",
	MODEL_STATUS_CANCELLED: "cancelled",
	MODEL_STATUS_EXPIRED:   "expired",
}

type FloSenseApiModel struct {
	Id                      string                 `json:"id,omitempty"`
	MacAddress              string                 `json:"macAddress"`
	SourceLocation          string                 `json:"sourceLocation,omitempty"`
	DownloadLocation        string                 `json:"downloadLocation,omitempty"`
	DeployTTL               int                    `json:"deployTtl,omitempty"`
	Tag                     string                 `json:"tag,omitempty"`
	Status                  string                 `json:"status,omitempty"`
	StatusMessage           string                 `json:"statusMessage,omitempty"`
	FirmwareProperties      map[string]interface{} `json:"fwProperties,omitempty"`
	Created                 time.Time              `json:"created,omitempty"`
	Updated                 time.Time              `json:"updated,omitempty"`
	Expires                 time.Time              `json:"expires,omitempty"`
	AppVersion              string                 `json:"appVersion"`
	ModelVersion            string                 `json:"modelVersion"`
	RefId                   string                 `json:"refId"`
	DisableSystemModeUpdate bool                   `json:"disableSystemModeUpdate"`
}

// Public Contract! Don't modify - you can add, but not change existing or remove
type FlosenseEntityActivity struct {
	Id                 string                 `json:"id,omitempty"`
	MacAddress         string                 `json:"macAddress"`
	SourceLocation     string                 `json:"sourceLocation,omitempty"`
	DownloadLocation   string                 `json:"downloadLocation,omitempty"`
	Tag                string                 `json:"tag,omitempty"`
	Status             string                 `json:"status,omitempty"`
	StatusMessage      string                 `json:"statusMessage,omitempty"`
	FirmwareProperties map[string]interface{} `json:"fwProperties,omitempty"`
	Created            time.Time              `json:"created,omitempty"`
	Updated            time.Time              `json:"updated,omitempty"`
	Expires            time.Time              `json:"expires,omitempty"`
	AppVersion         string                 `json:"appVersion,omitempty"`
	ModelVersion       string                 `json:"modelVersion,omitempty"`
	RefId              string                 `json:"refId,omitempty"`
}

func (self *FloSenseApiModel) ToEntityActivity() *FlosenseEntityActivity {
	if self == nil {
		return nil
	}

	return &FlosenseEntityActivity{
		Id:                 self.Id,
		MacAddress:         self.MacAddress,
		SourceLocation:     self.SourceLocation,
		DownloadLocation:   self.DownloadLocation,
		Tag:                self.Tag,
		Status:             self.Status,
		StatusMessage:      self.StatusMessage,
		Created:            self.Created,
		Updated:            self.Updated,
		Expires:            self.Expires,
		AppVersion:         self.AppVersion,
		ModelVersion:       self.ModelVersion,
		RefId:              self.RefId,
		FirmwareProperties: cloneMap(self.FirmwareProperties),
	}
}

func cloneMap(source map[string]interface{}) map[string]interface{} {
	if source == nil {
		return nil
	}
	if len(source) == 0 {
		return make(map[string]interface{})
	}

	// slow but reliable for deep copy
	j, _ := json.Marshal(source)
	rv := make(map[string]interface{})
	json.Unmarshal(j, &rv)
	return rv
}

var _postModelCount int64

func postFloSenseModelHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	body, err := httpReadBody(r)
	if err != nil {
		httpError(w, 400, "unable to read body", err)
		return
	}
	force := strings.EqualFold(getQueryParam(r, "force"), "true")

	model := FloSenseApiModel{}
	err = json.Unmarshal(body, &model)
	if err != nil {
		httpError(w, 400, "unable to deserialize json payload", err)
		return
	}

	logTrace("postFloSenseModelHandler: %v %v", mac, model)

	if len(model.SourceLocation) == 0 {
		httpError(w, 400, "sourceLocation is required", nil)
		return
	}
	if !strings.HasPrefix(model.SourceLocation, "http") {
		httpError(w, 400, "sourceLocation must be a valid http url. lowercase 'http://' or 'https://'", nil)
		return
	}
	if len(model.SourceLocation) > 1024 {
		httpError(w, 400, "sourceLocation is too long, 1024 max", nil)
		return
	}
	if len(model.Tag) > 255 {
		httpError(w, 400, "tag is too long, 255 max", nil)
		return
	}
	if len(model.RefId) > 128 {
		httpError(w, 400, "refId is too long, 128 max", nil)
		return
	}
	if model.DeployTTL <= 0 {
		model.DeployTTL = 604800
	}
	// Test JSON serialization
	if len(model.FirmwareProperties) > 0 {
		_, e := json.Marshal(model.FirmwareProperties)
		if e != nil {
			httpError(w, 400, "fwProperties has invalid format.", e)
			return
		}
	}
	if len(model.MacAddress) == 0 {
		model.MacAddress = mac
	}
	if !isValidMacAddress(model.MacAddress) {
		httpError(w, 400, "macAddress must be valid", nil)
		return
	}
	if !strings.EqualFold(mac, model.MacAddress) {
		httpError(w, 400, "macAddress and mac in url do not match", nil)
		return
	}
	model.MacAddress = strings.TrimSpace(strings.ToLower(model.MacAddress))

	// validate that device is not in re-learning mode
	floSenseData, err := getFloSenseFromDb(mac)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to get record for device %v", mac), err)
		return
	}
	if !model.DisableSystemModeUpdate && floSenseData != nil && floSenseData.ReLearningExpiresAt.After(time.Now()) {
		httpError(w, 400, fmt.Sprintf("device %v is in learning mode and should not receive new models until %v",
			mac, floSenseData.ReLearningExpiresAt), nil)
		return
	}

	// Prevent flood by rejecting clients
	new := atomic.AddInt64(&_postModelCount, 1)
	defer atomic.AddInt64(&_postModelCount, -1)

	if new > MAX_CONCURRENT_MODEL_POST {
		w.Header().Set("Retry-After", "5")
		httpWrite(w, 429, nil)
		return
	}

	// Download From Source
	fileData, err := downloadIntoArray(mac, model.SourceLocation)
	if err != nil {
		httpError(w, 400, "sourceLocation error (bad location, not binary, security)", err)
		return
	}

	// Parse the source manifest file
	manifest, err := parseManifestFromTarBzip2(fileData)
	if err != nil {
		httpError(w, 400, "manifest data error", err)
		return
	}

	model.AppVersion = manifest.AppVersion
	model.ModelVersion = manifest.ModelVersion

	if !force {
		if !isValidMacAddress(manifest.MacAddress) {
			httpError(w, 400, "manifest 'deviceid' is missing or invalid", nil)
			return
		}
		if !strings.EqualFold(model.MacAddress, manifest.MacAddress) {
			httpError(w, 400, "manifest 'deviceid' and url mac address mismatch", nil)
			return
		}
		if len(manifest.MinFwVersion) < 5 {
			httpError(w, 400, "manifest 'min_fw_version' is missing or invalid. format x.y.z", nil)
			return
		}
		if len(manifest.AppVersion) == 0 {
			httpError(w, 400, "manifest 'manifest_app_version' is missing or invalid", nil)
		}
		if len(manifest.ModelVersion) == 0 {
			httpError(w, 400, "manifest 'manifest_model_version' is missing or invalid", nil)
		}

		// Validate firmware version
		devInfo, err := getDeviceInfo(mac)
		if err != nil {
			httpError(w, 500, fmt.Sprintf("unable to retrieve device %v from api", mac), err)
			return
		}

		// Validate this is a flo device (not another type, e.g. puck)
		if !strings.Contains(strings.ToLower(devInfo.DeviceType), "flo_device") {
			httpError(w, 400, "only 'flo_device_*' device types support FloSense models", nil)
			return
		}
		// Validate version of the device
		if len(devInfo.FwVersion) == 0 {
			httpError(w, 400, "unknown device firmware version", nil)
			return
		}
		minVer, err := semver.Make(cleanVersion(manifest.MinFwVersion))
		if err != nil {
			httpError(w, 400, "unable to parse manifest min version", err)
			return
		}
		curVer, err := semver.Make(cleanVersion(devInfo.FwVersion))
		if err != nil {
			httpError(w, 400, "unable to parse device current version", err)
			return
		}
		if curVer.LT(minVer) {
			httpError(w, 400, fmt.Sprintf("current firmware version %v is below manifest min version %v", curVer.String(), minVer.String()), err)
			return
		}
	}

	created, err := createFlosenseModelRequest(&model)
	if err != nil {
		httpError(w, 500, "unable to create model record", err)
		return
	}

	created.DeployTTL = 0
	cancelPendingModels(model.MacAddress, model.Id)

	// Queue up data retrieval
	go func(i *FloSenseApiModel, data []byte) {
		postModelActivity("created", "", i.ToEntityActivity())

		err, _ := uploadFloSenseModelS3(i, data)
		if err == nil {
			sendInitialPropertiesToDevice(i)

			// Queue up property info in 5m
			go func(mac string) {
				time.Sleep(time.Minute * 5)
				dsSyncDevice(mac)
			}(i.MacAddress)
		}
	}(created, fileData)

	logDebug("postFloSenseModelHandler: model submitted %v %v", created.MacAddress, created.Id)
	httpWrite(w, 202, created)
}

func cleanVersion(current string) string {
	rv := strings.TrimSpace(current)
	if len(rv) == 0 {
		return rv
	}

	idx := strings.Index(rv, "-")
	if idx >= 0 {
		rv = rv[:idx]
	}

	split := strings.Split(rv, ".")
	if len(split) > 3 {
		rv = strings.Join(split[:3], ".")
	}

	return rv
}

func sendInitialPropertiesToDevice(item *FloSenseApiModel) {
	if item == nil || len(item.DownloadLocation) == 0 {
		logError("sendInitialPropertiesToDevice: item or download location is missing")
		return
	}

	// Protect from bombarding the device
	key := fmt.Sprint("mutex:flosense:deployment:%v", item.MacAddress)
	result, err := _redis.SetNX(key, tryToJson(item), 300)
	if err != nil {
		logError("sendInitialPropertiesToDevice: redis error. %v %v", item.MacAddress, err.Error())
		return
	}
	if !result {
		// There has already been an attempt to deploy in the last 60 seconds, wait for next retry
		return
	}

	send := make(map[string]interface{})

	// Set themodel download link - must be last in case someone overrides it in custom properties
	send[FWPROP_FLOSENSE_LINK] = item.DownloadLocation

	// Send shutoff level
	devInfo, _ := getOrCreateFromDb(item.MacAddress)
	if len(devInfo.MacAddress) == 12 {
		send[FWPROP_FLOSENSE_SHUTOFF_LEVEL] = devInfo.DeviceLevel
	}

	err = dsSendFwProperties(item.MacAddress, send)
	if err != nil {
		logError("sendInitialPropertiesToDevice: unable to send fw properties %v %v", item.Id, item.MacAddress)
		return
	}

	// Send sync request in case the fw props are out of sync
	go func(mac string) {
		time.Sleep(time.Minute * 5)
		dsSyncDevice(mac)
	}(item.MacAddress)

	logDebug("sendInitialPropertiesToDevice: sent to %v %v %v", item.Id, item.MacAddress, send)
}

func updateModelRecordState(modelId string, status int, statusMessage string) {

	if len(statusMessage) > 255 {
		statusMessage = statusMessage[:255]
	}

	_, err := _pgCn.ExecNonQuery("UPDATE \"flosense_models\" SET \"state\"=$2, \"state_message\"=$3, \"updated\"=$4 WHERE \"id\"=$1",
		modelId,
		status,
		statusMessage,
		time.Now().UTC().Truncate(time.Second))

	if err != nil {
		logError("updateModelRecordState: unable to update %v to %v %v. %v", modelId, status, statusMessage, err.Error())
		return
	}
}

func deleteFloSenseModelHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	id := mux.Vars(r)["id"]
	id = strings.ToLower(strings.TrimSpace(strings.Replace(id, "-", "", -1)))
	if len(id) != 32 {
		httpError(w, 400, "invalid id format", nil)
		return
	}

	req, err := _pgCn.ExecNonQuery("DELETE FROM flosense_models WHERE id=$1 AND state<=0", id)
	if err != nil {
		logError("deleteFloSenseModelHandler: %v %v %v", mac, id, err.Error())
		httpError(w, 500, "unable to delete record", err)
		return
	}
	count, _ := req.RowsAffected()
	if count > 0 {
		httpWrite(w, 200, nil)
	} else {
		httpWrite(w, 204, nil)
	}
}

func getFloSenseModelHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	id := mux.Vars(r)["id"]
	id = strings.ToLower(strings.TrimSpace(strings.Replace(id, "-", "", -1)))
	if !strings.EqualFold(id, "latest") && len(id) != 32 {
		httpError(w, 400, "invalid id format", nil)
		return
	}

	var rows *sql.Rows
	if strings.EqualFold(id, "latest") {
		r, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
			" FROM flosense_models "+
			" WHERE device_id=$1 ORDER BY created DESC LIMIT 1;",
			mac)
		if e != nil {
			httpError(w, 500, "unable to query database", e)
			return
		}
		defer r.Close()
		rows = r
	} else {
		r, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
			" FROM flosense_models "+
			" WHERE id=$1;",
			id)
		if e != nil {
			httpError(w, 500, "unable to query database", e)
			return
		}
		defer r.Close()
		rows = r
	}

	if rows.Next() {
		delta := parseModelDbRecord(rows)
		if delta == nil {
			httpError(w, 500, "unable to parse db record", nil)
		} else {
			httpWrite(w, 200, delta)
		}
	} else {
		httpWrite(w, 404, nil)
	}
}

func listFloSenseModelHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	tag := getQueryParam(r, "tag")

	var rows *sql.Rows

	if len(tag) > 0 {
		r, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
			" FROM flosense_models "+
			" WHERE device_id=$1 AND tag ILIKE $2 ORDER BY created DESC LIMIT 52",
			mac, "%"+tag+"%")
		if e != nil {
			httpError(w, 500, "unable to query database", e)
			return
		}
		defer r.Close()
		rows = r
	} else {
		r, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
			" FROM flosense_models "+
			" WHERE device_id=$1 ORDER BY created DESC LIMIT 52",
			mac)
		if e != nil {
			httpError(w, 500, "unable to query database", e)
			return
		}
		defer r.Close()
		rows = r
	}

	rv := make([]*FloSenseApiModel, 0)
	for rows.Next() {
		delta := parseModelDbRecord(rows)
		rv = append(rv, delta)
	}

	httpWrite(w, 200, map[string]interface{}{
		"items":      rv,
		"count":      len(rv),
		"macAddress": mac,
	})
}

func parseModelDbRecord(rows *sql.Rows) *FloSenseApiModel {
	delta := new(FloSenseApiModel)
	stateInt := 0
	fwPropString := ""

	err := rows.Scan(&delta.Id, &delta.MacAddress, &stateInt,
		&delta.StatusMessage, &delta.SourceLocation, &delta.DownloadLocation,
		&delta.Tag, &fwPropString, &delta.Created, &delta.Updated,
		&delta.Expires, &delta.AppVersion, &delta.ModelVersion, &delta.RefId, &delta.DisableSystemModeUpdate)

	if err != nil {
		logError("parseModelDbRecord: %v", err.Error())
		return nil
	}

	if len(fwPropString) > 2 {
		x := make(map[string]interface{})
		e := json.Unmarshal([]byte(fwPropString), &x)
		if e != nil {
			logWarn("listFloSenseModelHandler: unable to deserialize properties for %v %v", delta.Id, delta.MacAddress)
		}
		delta.FirmwareProperties = x
	}

	delta.Status = ModelStatusLookup[stateInt]

	return delta
}

func getQueryParam(r *http.Request, paramName string) string {
	if len(paramName) == 0 || r == nil || r.URL == nil || len(r.URL.Query()) == 0 {
		return ""
	}

	x := r.URL.Query()[paramName]
	if len(x) > 0 {
		return strings.Join(x, " ")
	}

	return ""
}

func createFlosenseModelRequest(item *FloSenseApiModel) (*FloSenseApiModel, error) {
	if item == nil {
		return nil, logError("createFlosenseModelRequest: nil item")
	}
	if len(item.Id) != 0 {
		return nil, logError("createFlosenseModelRequest: id must be empty for create")
	}

	now := time.Now().UTC().Truncate(time.Second)

	item.Status = ModelStatusLookup[MODEL_STATUS_QUEUED]
	item.Id = newPk()
	item.Created = now
	item.Updated = now
	item.Expires = now.Add(time.Duration(item.DeployTTL) * time.Second)

	props := "{}"
	if len(item.FirmwareProperties) > 0 {
		x, e := json.Marshal(item.FirmwareProperties)
		if e != nil {
			return nil, logError("createFlosenseModelRequest: unable to serialize firmwareProperties. %v", e.Error())
		}
		props = string(x)
	}

	disableSystemModeUpdateNum := 0
	if item.DisableSystemModeUpdate {
		disableSystemModeUpdateNum = 1
	}

	_, err := _pgCn.ExecNonQuery("INSERT INTO \"flosense_models\" (\"id\",\"device_id\",\"state\",\"source_url\",\"tag\",\"fw_properties\",\"app_version\",\"model_version\",\"created\",\"updated\",\"expire\",\"ref_id\",\"disable_system_mode_update\") "+
		" VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13);",
		item.Id,
		item.MacAddress,
		MODEL_STATUS_QUEUED,
		item.SourceLocation,
		item.Tag,
		props,
		item.AppVersion,
		item.ModelVersion,
		item.Created,
		item.Updated,
		item.Expires,
		item.RefId,
		disableSystemModeUpdateNum,
	)

	if err != nil {
		return nil, logError("createFlosenseModelRequest: unable to create db record. %v", err.Error())
	}

	logDebug("createFlosenseModelRequest: Created %v %v", item.Id, item.MacAddress)

	return item, nil
}

func cancelPendingModels(macAddress string, latestId string) {
	if !isValidMacAddress(macAddress) {
		logError("cancelPendingModels: invalid mac address")
		return
	}
	if len(latestId) != 32 {
		logError("cancelPendingModels: invalid latestId")
		return
	}

	req, err := _pgCn.Query("UPDATE \"flosense_models\" SET \"state\"=$4, \"state_message\"=$5 "+
		" WHERE \"device_id\"=$1 AND (\"state\"=$2 OR \"state\"=$6) AND \"id\"!=$3"+
		" RETURNING \"id\",\"device_id\",\"ref_id\",\"state\",\"state_message\",\"updated\";",
		macAddress,
		MODEL_STATUS_QUEUED,
		latestId,
		MODEL_STATUS_CANCELLED,
		latestId,
		MODEL_STATUS_READY)

	if err != nil {
		logError("cancelPendingModels: %v %v %v", macAddress, latestId, err.Error())
		return
	}
	defer req.Close()

	updated := make([]*FloSenseApiModel, 0)

	for req.Next() {
		stateInt := 0
		delta := new(FloSenseApiModel)
		err := req.Scan(&delta.Id, &delta.MacAddress, &delta.RefId, &stateInt, &delta.StatusMessage, &delta.Updated)

		if err != nil {
			continue
		}
		delta.Status = ModelStatusLookup[stateInt]
		updated = append(updated, delta)
	}

	for _, u := range updated {
		logDebug("cancelPendingModels: Cancelled model %v %v", u.Id, u.MacAddress)
		go postModelActivity("updated", "", u.ToEntityActivity())
	}
}

func initDevicePropertiesWorker() {
	kafka, _ := OpenKafka(_kafkaCn)
	topics := []string{KAFKA_DEVICE_PROPERTIES_TOPIC}

	if kafka == nil {
		logError("initDevicePropertiesWorker: Can't continue, exiting")
		os.Exit(-20)
	}

	_, err := kafka.Subscribe(_kafkaGroupId, topics, processPropertiesTopicWorker)

	if err != nil {
		logError("initDevicePropertiesWorker: Can't subscribe to topics, exiting. %v", topics)
		os.Exit(-20)
	}
}

func processPropertiesTopicWorker(item *kafka.Message) {
	if item == nil || len(item.Value) == 0 {
		return
	}

	props := DevicePropertiesTopicModel{}
	err := json.Unmarshal(item.Value, &props)
	if err != nil {
		logError("processPropertiesTopicWorker: %v %v", err.Error(), string(item.Value))
		return
	}
	if !isValidMacAddress(props.DeviceId) {
		logError("processPropertiesTopicWorker: invalid mac address %v", props.DeviceId)
		return
	}

	updateFlosenseLevel(&props)
	confirmFlosenseVersion(&props)
}

func updateFlosenseLevel(props *DevicePropertiesTopicModel) {
	if props == nil || len(props.Properties) == 0 {
		return
	}

	floSenseLevel := props.Properties[FWPROP_FLOSENSE_SHUTOFF_LEVEL]

	// Property not there, ignore
	if floSenseLevel == nil {
		return
	}

	x := fmt.Sprintf("%v", floSenseLevel)
	i, e := strconv.ParseInt(x, 10, 64)
	if e != nil {
		return
	}

	if i >= 0 && i <= 100 {
		r, _ := _pgCn.ExecNonQuery("UPDATE \"flosense\" SET \"device_level_last\"=$2 WHERE \"device_id\"=$1", props.DeviceId, i)
		c, _ := r.RowsAffected()
		if c > 0 {
			logDebug("processPropertiesTopicWorker: confirmed device floSense level. %v %v", props.DeviceId, i)
		}
	}
}

func confirmFlosenseVersion(props *DevicePropertiesTopicModel) {
	if props == nil || len(props.Properties) == 0 {
		return
	}

	// Extra the version of model and app
	recAppVersion := props.Properties["flosense_version_app"]
	recModelVersion := props.Properties["flosense_version_model"]
	if recAppVersion == nil || recModelVersion == nil {
		return
	}

	recAppVersionString := fmt.Sprintf("%v", recAppVersion)
	recModelVersionString := fmt.Sprintf("%v", recModelVersion)
	if len(recAppVersionString) == 0 || len(recModelVersionString) == 0 {
		return
	}

	// Extract the status of the deployment
	// installing, success, error_download, error_deviceid, error_start
	deployResult := strings.ToLower(tryGetInterfaceAsString(props.Properties["flosense_deployment_result"]))
	floSenseState := tryGetInterfaceAsString(props.Properties["flosense_state"])

	if len(deployResult) == 0 && len(floSenseState) == 0 {
		logDebug("confirmFlosenseVersion: flosense_deployment_result and flosense_state are empty %v",
			props.DeviceId)
		return
	}

	// Pending install
	if strings.EqualFold(deployResult, "installing") {
		logDebug("confirmFlosenseVersion: installing %v %v %v",
			props.DeviceId, recAppVersionString, recModelVersionString)
		return
	}

	// Error
	if strings.HasPrefix(deployResult, "error_") {
		logError("confirmFlosenseVersion: error confirming %v %v %v %v",
			props.DeviceId, recAppVersionString, recModelVersionString, deployResult)
		return
	}

	// SUCCESS
	if strings.EqualFold(deployResult, "success") && strings.EqualFold(floSenseState, "active") {
		updateFloSenseVersion(props, recAppVersionString, recModelVersionString)
		return
	}

	// Unknown
	logWarn("confirmFlosenseVersion: invalid deployment state: '%v' '%v' %v %v %v %v",
		deployResult, floSenseState, props.DeviceId, recAppVersionString, recModelVersionString, deployResult)
	return
}

func updateFloSenseVersion(props *DevicePropertiesTopicModel, appVersion string, modelVersion string) {

	rows, err := _pgCn.Query("UPDATE flosense_models SET state=$4, updated=$5 "+
		" WHERE device_id=$1 AND app_version=$2 AND model_version=$3 AND state >= 0 AND state != $4"+
		" RETURNING \"id\",\"device_id\",\"ref_id\",\"state\",\"state_message\",\"updated\",\"disable_system_mode_update\";",
		props.DeviceId,
		appVersion,
		modelVersion,
		MODEL_STATUS_DEPLOYED,
		time.Now().UTC().Truncate(time.Second),
	)

	if err != nil {
		logError("updateFloSenseVersion: error confirming. %v %v", props.DeviceId, err.Error())
		return
	}

	defer rows.Close()

	updated := make([]*FloSenseApiModel, 0)

	for rows.Next() {
		stateInt := 0
		delta := new(FloSenseApiModel)
		err := rows.Scan(&delta.Id, &delta.MacAddress, &delta.RefId, &stateInt, &delta.StatusMessage, &delta.Updated, &delta.DisableSystemModeUpdate)

		if err != nil {
			continue
		}
		delta.Status = ModelStatusLookup[stateInt]
		updated = append(updated, delta)
	}

	if len(updated) > 0 {
		disableSystemModeUpdate := false
		for _, u := range updated {
			if u.DisableSystemModeUpdate {
				disableSystemModeUpdate = true
			}
			logDebug("updateFloSenseVersion: Confirmed FloSense Model changes %v %v %v %v",
				u.Id, u.MacAddress, appVersion, modelVersion)
			go postModelActivity("updated", "model-confirmed", u.ToEntityActivity())
		}

		sendFollowUpProperties(props.DeviceId, appVersion, modelVersion)

		if !disableSystemModeUpdate {
			updateDeviceSystemMode(props)
			defaultTime, _ := time.Parse("2006-01-02", "1970-01-01")
			updateLearningData(props.DeviceId, &defaultTime, 0)
		} else {
			logDebug("updateFloSenseVersion: Ignoring system mode update for device: %v, disableSystemModeUpdate: %v", props.DeviceId, disableSystemModeUpdate)
		}
	}
}

func tryGetInterfaceAsString(value interface{}) string {
	if value == nil {
		return ""
	}

	rv, _ := value.(string)
	return rv
}

func updateDeviceSystemMode(props *DevicePropertiesTopicModel) {
	if props == nil || len(props.Properties) == 0 {
		return
	}

	// Check for the system mode from the device
	propSysMode := props.Properties["system_mode"]
	if propSysMode == nil {
		logDebug("updateDeviceSystemMode: 'system_mode' is missing from properties. Continue anyway to check if is locked. %v", props.DeviceId)
	} else {
		sysModeStr := fmt.Sprintf("%v", propSysMode)
		if sysModeStr != "5" {
			logDebug("updateDeviceSystemMode: device property system mode not in sleep, Continue anyway to check if is locked. %v", props.DeviceId)
		}
	}

	// Retrieve the device from api to get device and location system mode values
	devInfo, err := getDeviceInfo(props.DeviceId)
	if err != nil {
		logError("updateDeviceSystemMode: error retrieving device from api. %v %v", props.DeviceId, err.Error())
		return
	}

	// We are looking for a device in FORCED SLEEP only OR an unlocked device but with permanent SLEEP (revertMinutes equal to zero)
	nonLockedException := devInfo.SystemMode.LastKnown != SYSTEM_MODE_SLEEP || devInfo.SystemMode.RevertMinutes != 0
	if !devInfo.SystemMode.IsLocked && nonLockedException {
		logDebug("updateDeviceSystemMode: device system mode not in locked sleep, skipping. %v %v", devInfo.MacAddress, devInfo.SystemMode)
		return
	}

	// validate and LOG inconsistencies and continue unlocking the device.
	if devInfo.SystemMode.Target != SYSTEM_MODE_SLEEP || devInfo.SystemMode.LastKnown != SYSTEM_MODE_SLEEP {
		logDebug("updateDeviceSystemMode: Inconsistencies found for device system mode (target/lastKnow). Proceed to unlock the device anyway. %v %v", devInfo.MacAddress, devInfo.SystemMode)
	}

	// Location system mode is missing/invalid, can't assume
	if len(devInfo.Location.SystemMode.Target) == 0 {
		logError("updateDeviceSystemMode: Location target empty. %v. Continue anyway and using HOME as default mode", devInfo.MacAddress)
	}

	if devInfo.SystemMode.IsLocked {
		_, err = UnlockDeviceSystemMode(devInfo.Id)
		if err != nil {
			logWarn("updateDeviceSystemMode: failed to unlock device system mode. %v %v", devInfo.MacAddress, err.Error())
		}
	}

	// Do not put a device to sleep, put it in home mode if location is in sleep
	target := devInfo.Location.SystemMode.Target
	if target == SYSTEM_MODE_SLEEP || len(target) == 0 {
		target = SYSTEM_MODE_HOME
	}

	_, err = SetDeviceTargetSystemMode(devInfo.Id, target)
	if err != nil {
		logError("updateDeviceSystemMode: failed to set device system mode. %v %v %v", devInfo.MacAddress, devInfo.Location.SystemMode.Target, err.Error())
		return
	}

	logDebug("updateDeviceSystemMode: set device system mode. %v %v", devInfo.MacAddress, devInfo.Location.SystemMode.Target)
}

func sendFollowUpProperties(macAddress string, appVersion string, modelVersion string) {
	if !isValidMacAddress(macAddress) || len(appVersion) == 0 || len(modelVersion) == 0 {
		logWarn("sendFollowUpProperties: mac, app ver, or model ver is invalid.")
		return
	}

	// select the LATEST record
	r, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
		" FROM flosense_models "+
		" WHERE device_id=$1 AND app_version=$2 AND model_version=$3 AND state=$4"+
		" ORDER BY created DESC LIMIT 1;",
		macAddress,
		appVersion,
		modelVersion,
		MODEL_STATUS_DEPLOYED)
	if e != nil {
		logError("sendFollowUpProperties: db error %v %v %v %v", macAddress, appVersion, modelVersion, e.Error())
		return
	}
	defer r.Close()

	var delta *FloSenseApiModel = nil
	if r.Next() {
		delta = parseModelDbRecord(r)
	}
	if delta == nil {
		logWarn("sendFollowUpProperties: unable to find deployed flosense model for %v %v %v", macAddress, appVersion, modelVersion)
		return
	}

	// No properties to send
	if len(delta.FirmwareProperties) == 0 {
		logDebug("sendFollowUpProperties: no properties queued for flosense model for %v %v %v", macAddress, appVersion, modelVersion)
		return
	}

	// Send shutoff level
	devInfo, _ := getOrCreateFromDb(macAddress)
	if isValidMacAddress(devInfo.MacAddress) {
		delta.FirmwareProperties[FWPROP_FLOSENSE_SHUTOFF_LEVEL] = devInfo.DeviceLevel
	}

	err := dsSendFwProperties(delta.MacAddress, delta.FirmwareProperties)
	if err != nil {
		logError("sendFollowUpProperties: error sending properties. %v %v %v %v", macAddress, appVersion, modelVersion, err.Error())
		return
	}

	logDebug("sendFollowUpProperties: sent followup properties. %v %v %v %v", macAddress, appVersion, modelVersion, delta.FirmwareProperties)
}

type DevicePropertiesTopicModel struct {
	Id         string                 `json:"id"`
	RequestId  string                 `json:"request_id"`
	DeviceId   string                 `json:"device_id"`
	Reason     string                 `json:"reason"`
	Timestamp  int64                  `json:"timestamp"`
	Properties map[string]interface{} `json:"properties"`
}

func syncFloSenseModelHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	// select the LATEST READY record from device
	result, e := _pgCn.Query("SELECT id,device_id,state,state_message,source_url,download_url,tag,fw_properties,created,updated,expire,app_version,model_version,ref_id,disable_system_mode_update "+
		" FROM flosense_models "+
		" WHERE device_id=$1 AND state=$2"+
		" ORDER BY created DESC LIMIT 1;",
		mac,
		MODEL_STATUS_READY)
	if e != nil {
		logError("syncFloSenseModelHandler: db error %v %v", mac, e.Error())
		httpError(w, 500, "db error", nil)
		return
	}
	defer result.Close()

	var delta *FloSenseApiModel = nil
	if result.Next() {
		delta = parseModelDbRecord(result)
	}
	if delta == nil {
		logWarn("syncFloSenseModelHandler: unable to find a READY flosense model for %v", mac)
		httpError(w, 404, "unable to find a READY flosense model", nil)
		return
	}
	if len(delta.DownloadLocation) == 0 {
		logWarn("syncFloSenseModelHandler: download link should not be empty for %v", mac)
		httpError(w, 400, "invalid download link", nil)
		return
	}

	// Queue up data retrieval
	go sendInitialPropertiesToDevice(delta)
	logDebug("syncFloSenseModelHandler: properties sent to device %v %v", mac, delta.Id)
	httpWrite(w, 202, delta)
}
