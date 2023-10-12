package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"time"

	"github.com/go-errors/errors"

	"github.com/gorilla/mux"

	httpSwagger "github.com/swaggo/http-swagger"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
	_ "gitlab.com/flotechnologies/flo-detect-v2/docs"
)

var muxRouter *mux.Router
var webServer *http.Server

func startWeb(port int) {
	// Register the routes
	muxRouter = mux.NewRouter()
	tracing.WrapMux(tracing.Instana, muxRouter)
	muxRouter.HandleFunc("/docs", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/swagger/index.html", http.StatusFound)
	})
	muxRouter.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)

	muxRouter.HandleFunc("/ping", httpMidWare("pingHandler", pingHandler)).Methods("GET", "get")

	muxRouter.HandleFunc("/kafka/event", httpMidWare("fixtureEventPostHandler", fixtureEventPostHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/kafka/irrigation", httpMidWare("irrigationEventPostHandler", irrigationEventPostHandler)).Methods("POST", "post")

	muxRouter.HandleFunc("/events", httpMidWare("eventReportHandler", eventReportHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/events/{id}", httpMidWare("eventPostHandler", eventPostHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/events/{id}", httpMidWare("eventGetHandler", eventGetHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/events/{id}", httpMidWare("eventDeleteHandler", eventDeleteHandler)).Methods("DELETE", "delete")

	muxRouter.HandleFunc("/fixtures", httpMidWare("fixtureReportHandler", fixtureReportHandler)).Methods("GET", "get")

	muxRouter.HandleFunc("/irrigation/{mac}", httpMidWare("irrigationGetHandler", irrigationGetHandler)).Methods("GET", "get")
	muxRouter.HandleFunc("/irrigation/{mac}", httpMidWare("irrigationPostHandler", irrigationPostHandler)).Methods("POST", "post")
	muxRouter.HandleFunc("/irrigation/{mac}", httpMidWare("irrigationDeleteHandler", irrigationDeleteHandler)).Methods("DELETE", "delete")

	muxRouter.HandleFunc("/trends", httpMidWare("trendsReportHandler", trendsReportHandler)).Methods("GET", "get")

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
// @Tags System
// @Accept  json
// @Produce  json
// @Success 200
// @Router /ping [get]
// PingHandler is the handler for healthcheck aka ping
func pingHandler(w http.ResponseWriter, r *http.Request) {

	rv := map[string]interface{}{
		"date":           time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":            APP_NAME,
		"status":         "ok",
		"commit":         _commitSha,
		"commitTime":     _commitTime,
		"host":           _hostName,
		"env":            getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
		"uptime":         int64(time.Now().Sub(_start).Seconds()),
		"goRoutineCount": runtime.NumGoroutine(),
	}

	httpWrite(w, 200, rv)
}

func httpError(w http.ResponseWriter, code int, msg string, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)

	rv := &HttpErrorResponse{
		Code:    code,
		Message: msg,
	}

	if err != nil {
		rv.Developer = err.Error()
	}

	js, _ := json.Marshal(rv)
	_, err = w.Write(js)

	if err != nil {
		logError("httpError: %v", err.Error())
	}
}

type HttpErrorResponse struct {
	Code      int    `json:"code,omitempty"`
	Message   string `json:"message,omitempty"`
	Developer string `json:"developer,omitempty"`
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

func httpMidWare(name string, f http.HandlerFunc) http.HandlerFunc {
	if tracing.Instana != nil {
		return tracing.Instana.TracingHandler(name, handerPanicRecover(f))
	} else {
		return handerPanicRecover(f)
	}
}

func handerPanicRecover(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		defer func() {
			r := recover()
			if r != nil {
				var err error
				switch t := r.(type) {
				case string:
					err = errors.New(t)
				case error:
					err = t
					e := errors.Wrap(err, 2)
					err = e
					defer logError(e.ErrorStack())
				default:
					err = errors.New("Unknown error")
				}
				logError("%v %v | %v | => %v", req.Method, req.URL, req.Header, err.Error())
				httpError(w, 503, "panicRecover", err)
			}
		}()
		h.ServeHTTP(w, req)
	}
}
