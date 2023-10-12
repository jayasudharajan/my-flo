package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	httpSwagger "github.com/swaggo/http-swagger"

	"github.com/gorilla/mux"
	_ "gitlab.com/flotechnologies/flo-science-lab/docs"
)

var muxRouter *mux.Router
var webServer *http.Server

func startWeb(port int) {
	// Register the routes
	muxRouter = mux.NewRouter()

	muxRouter.HandleFunc("/docs", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/swagger/index.html", http.StatusFound)
	})
	muxRouter.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)

	muxRouter.HandleFunc("/ping", _instana.TracingHandler("pingHandler", PingHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/devices/{mac}", _instana.TracingHandler("getDeviceHandler", getDeviceHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/devices/{mac}", _instana.TracingHandler("postDeviceHandler", postDeviceHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}", _instana.TracingHandler("deleteDeviceHandler", deleteDeviceHandler)).Methods("DELETE", "delete")

	muxRouter.HandleFunc("/devices/{mac}/floSense/models", _instana.TracingHandler("postFloSenseModelHandler", postFloSenseModelHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}/floSense/models", _instana.TracingHandler("listFloSenseModelHandler", listFloSenseModelHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/devices/{mac}/floSense/models/{id}", _instana.TracingHandler("deleteFloSenseModelHandler", deleteFloSenseModelHandler)).Methods("DELETE", "delete")
	muxRouter.HandleFunc("/devices/{mac}/floSense/models/{id}", _instana.TracingHandler("getFloSenseModelHandler", getFloSenseModelHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/devices/{mac}/floSense/models/sync", _instana.TracingHandler("syncFloSenseModelHandler", syncFloSenseModelHandler)).Methods("POST", "post")

	muxRouter.HandleFunc("/devices/{mac}/learning", _instana.TracingHandler("postLearningHandler", postLearningHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}/learning", _instana.TracingHandler("getLearningHandler", getLearningHandler)).Methods("GET", "get")

	muxRouter.HandleFunc("/devices/{mac}/pes/schedule", _instana.TracingHandler("postPesScheduleHandler", postPesScheduleHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}/pes/schedule/pull", _instana.TracingHandler("pullPesScheduleHandler", pullPesScheduleHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}/pes/schedule/sync", _instana.TracingHandler("syncPesScheduleHandler", syncPesScheduleHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/devices/{mac}/pes/schedule/{id}", _instana.TracingHandler("deletePesScheduleHandler", deletePesScheduleHandler)).Methods("DELETE", "delete")
	muxRouter.HandleFunc("/devices/{mac}/pes/schedule/{id}", _instana.TracingHandler("replacePesScheduleHandler", replacePesScheduleHandler)).Methods("PUT", "put")

	// Create web server instance
	webServer = &http.Server{
		Addr: fmt.Sprintf("0.0.0.0:%v", port),
		// Good practice to set timeouts to avoid Slowloris attacks.
		WriteTimeout: time.Second * 15,
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      muxRouter, // Pass our instance of gorilla/mux in.
	}

	// Run our server in a goroutine (separate thread) so that it doesn't block.
	go func() {
		logNotice("Starting HTTP Api on port %v", port)
		if err := webServer.ListenAndServe(); err != nil {
			logError(err.Error())
		}
	}()
}

func stopWeb() {
	// Create a deadline to wait for.
	wait := time.Duration(30 * time.Second)
	ctx, cancel := context.WithTimeout(context.Background(), wait)
	defer cancel()

	err := webServer.Shutdown(ctx)

	if err != nil {
		logError("stopWeb: %v", err.Error())
	}
}

// PingDeviceService godoc
// @Summary check the health status of the service and list its config data
// @Description returns status of the service
// @Tags system
// @Accept  json
// @Produce  json
// @Success 200
// @Router /ping [get]
// PingHandler is the handler for healthcheck aka ping
func PingHandler(w http.ResponseWriter, r *http.Request) {

	rv := map[string]interface{}{
		"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":        APP_NAME,
		"status":     "ok",
		"commit":     _commitSha,
		"commitTime": _commitTime,
		"host":       _hostName,
		"env":        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
	}

	httpWrite(w, 200, rv)
}

func httpError(w http.ResponseWriter, code int, msg string, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)

	rv := map[string]interface{}{
		"code":    code,
		"message": msg,
	}

	if err != nil {
		rv["developer"] = err.Error()
	}

	js, _ := json.Marshal(rv)
	_, err = w.Write(js)

	if err != nil {
		logError("httpError: %v", err.Error())
	}
}

func httpWrite(w http.ResponseWriter, code int, item interface{}) {
	var rvJson []byte

	if item != nil {
		j, err := json.Marshal(item)
		if err != nil {
			logError("httpWrite: error serializing object to json %v", item)
			httpError(w, 500, "unable to serialize response", err)
			return
		}
		rvJson = j
	}

	id, _, _ := newUuid()
	w.Header().Set("x-request-id", id)
	w.Header().Set("x-host", _hostName)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)

	if len(rvJson) > 0 {
		_, err := w.Write(rvJson)

		if err != nil {
			logError("httpWrite: %v", err.Error())
		}
	}
}

func httpReadBody(r *http.Request) ([]byte, error) {
	if r == nil {
		return nil, logError("httpReadBody: request is nil")
	}
	if r.Body == nil {
		return nil, logError("httpReadBody: body is nil")
	}
	defer r.Body.Close()
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return nil, logError("httpReadBody: error reading http body. %v", err.Error())
	}
	return body, nil
}
