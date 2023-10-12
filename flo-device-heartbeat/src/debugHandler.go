package main

import (
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

type DebugResponseModel struct {
	MacAddress  string                    `json:"macAddress,omitempty"`
	CurrentDate time.Time                 `json:"currentDate,omitempty"`
	Database    DebugStorageResponseModel `json:"database"`
	Firestore   DebugStorageResponseModel `json:"firestore"`
	Redis       DebugStorageResponseModel `json:"redis"`
}
type DebugStorageResponseModel struct {
	IsConnected bool   `json:"isConnected"`
	NotFound    bool   `json:"notFound,omitempty"`
	Error       string `json:"error,omitempty"`
}

func debugDeviceHandler(w http.ResponseWriter, r *http.Request) {
	macAddress := strings.ToLower(strings.TrimSpace(mux.Vars(r)["mac"]))

	if len(macAddress) != 12 {
		httpError(w, 400, "macAddress in query parameter missing/invalid", nil)
		return
	}

	dbRecord := getStateFromDatabase(macAddress)
	fsRecord := getStateFromFirestore(macAddress)
	redisRecord := getStateFromRedis(macAddress)

	rv := DebugResponseModel{}
	rv.MacAddress = macAddress
	rv.CurrentDate = time.Now().UTC().Truncate(time.Second)

	rv.Database.IsConnected = dbRecord.Online
	rv.Database.NotFound = dbRecord.NotFound
	if dbRecord.Error != nil {
		rv.Database.Error = dbRecord.Error.Error()
	}

	rv.Firestore.IsConnected = fsRecord.Online
	rv.Firestore.NotFound = fsRecord.NotFound
	if fsRecord.Error != nil {
		rv.Firestore.Error = fsRecord.Error.Error()
	}

	rv.Redis.IsConnected = redisRecord.Online
	rv.Redis.NotFound = redisRecord.NotFound
	if redisRecord.Error != nil {
		rv.Redis.Error = redisRecord.Error.Error()
	}

	httpWrite(w, 200, rv)
}

func getStateHandler(w http.ResponseWriter, r *http.Request) {
	macAddress := strings.ToLower(strings.TrimSpace(mux.Vars(r)["mac"]))

	if len(macAddress) != 12 {
		httpError(w, 400, "macAddress in query parameter missing/invalid", nil)
		return
	}

	redisRecord := getStateFromRedis(macAddress)

	rv := map[string]interface{}{
		"macAddress":  macAddress,
		"currentDate": time.Now().UTC().Format(time.RFC3339),
		"isConnected": redisRecord.Online,
	}

	httpWrite(w, 200, rv)
}
