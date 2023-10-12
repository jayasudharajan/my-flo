package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

var muxRouter *mux.Router
var webServer *http.Server

func startWeb(port int) {
	muxRouter = mux.NewRouter()
	muxRouter.HandleFunc("/ping", _instana.TracingHandler("pingHandler", pingHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/state", _instana.TracingHandler("setStateHandler", setStateHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/state/{mac}", _instana.TracingHandler("getStateHandler", getStateHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/debug/{mac}", _instana.TracingHandler("debugDeviceHandler", debugDeviceHandler)).Methods("GET", "get")

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

func httpGetExpectedBody(r *http.Request, item interface{}) error {

	x := r.Body
	if x == nil {
		return errors.New("body missing")
	}
	defer x.Close()

	b, e := ioutil.ReadAll(x)
	if len(b) == 0 {
		return errors.New("empty body")
	}

	e = json.Unmarshal(b, item)
	if e != nil {
		return e
	}

	return nil
}

func pingHandler(w http.ResponseWriter, r *http.Request) {

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
