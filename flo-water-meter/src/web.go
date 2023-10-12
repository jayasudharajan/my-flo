package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"

	//"github.com/pkg/errors"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/go-errors/errors"
	"github.com/gorilla/mux"
)

const ENVVAR_GRAFANA_BSAUTH_USER = "FLO_GRAFANA_BSAUTH_USER"
const ENVVAR_GRAFANA_BSAUTH_PWD = "FLO_GRAFANA_BSAUTH_PWD"

var muxRouter *mux.Router = mux.NewRouter()
var webServer *http.Server
var tsWaterReader WaterReader
var kfWaterConsumer *WaterConsumer
var s3Handler *GrafanaWebHandler

func setupRoutes(ts WaterReader, kwc *WaterConsumer, s3 *GrafanaWebHandler) {
	tsWaterReader = ts
	s3Handler = s3
	kfWaterConsumer = kwc
	authMap := map[string]string{}
	gUsr := getEnvOrDefault(ENVVAR_GRAFANA_BSAUTH_USER, "")
	if gUsr != "" { //test user & pwd: flo_testa    &   Fl0_r1dAz002hD82Z3899e1110f9CzM =>  Authorization basic ZmxvX3Rlc3RhOkZsMF9yMWRBejAwMmhEODJaMzg5OWUxMTEwZjlDek0K
		gPwd := getEnvOrDefault(ENVVAR_GRAFANA_BSAUTH_PWD, "")
		authMap[gUsr] = gPwd
	}

	//endpoints for Grafana
	muxRouter.HandleFunc("/grafana", httpMidWareWithAuthDec(pingHandler, authMap)).Methods("GET", "POST", "OPTIONS")
	muxRouter.HandleFunc("/grafana/search", httpMidWareWithAuthDec(s3Handler.Search, authMap)).Methods("POST", "OPTIONS")
	muxRouter.HandleFunc("/grafana/query", httpMidWareWithAuthDec(s3Handler.Query, authMap)).Methods("POST", "OPTIONS")
	muxRouter.HandleFunc("/grafana/annotations", httpMidWareWithAuthDec(s3Handler.Annotations, authMap)).Methods("POST", "OPTIONS")
	muxRouter.HandleFunc("/grafana/tag-keys", httpMidWareWithAuthDec(s3Handler.TagKeys, authMap)).Methods("GET", "POST", "OPTIONS")

	//endpoints for water usage
	muxRouter.HandleFunc("/", httpMidWareDec(pingHandler)).Methods("GET")
	muxRouter.HandleFunc("/ping", httpMidWareDec(pingHandler)).Methods("GET", "POST")
	muxRouter.HandleFunc("/sync", httpMidWareDec(syncRequest)).Methods("POST")
	muxRouter.HandleFunc("/audit", httpMidWareDec(auditRequest)).Methods("POST")
	muxRouter.HandleFunc("/report", httpMidWareDec(consumptionHandler)).Methods("GET")
	muxRouter.HandleFunc("/latest", httpMidWareDec(latestTelemetryHandler)).Methods("GET")

	muxRouter.HandleFunc("/ts/refresh", httpMidWareDec(aggRefresh)).Methods("POST")

	muxRouter.HandleFunc("/device/{id:[a-f0-9]+}", httpMidWareDec(getSrcDataHandler)).Methods("GET")
	muxRouter.HandleFunc("/device/{id:[a-f0-9]+}", httpMidWareDec(removeDataHandler)).Methods("DELETE") //NOTE: admin token is required for this op for safety
	if strings.EqualFold(getEnvOrDefault("FLO_ALLOW_RM_KEYS", ""), "true") {
		_log.Notice("FLO_ALLOW_RM_KEYS=true")
		muxRouter.HandleFunc("/old", httpMidWareDec(removeOldDataHandler)).Methods("DELETE") //remove all 201* water meter telemetry data
	}
}

func startWeb(port int) {
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
	wait := time.Duration(5 * time.Second)
	ctx, cancel := context.WithTimeout(context.Background(), wait)
	defer cancel()

	webServer.Shutdown(ctx)
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	var (
		started = time.Now()
		code    = 200 //OK
		rv      = map[string]interface{}{
			"date":   time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":    APP_NAME,
			"status": "OK",
			"commit": commitSha,
			"host":   _hostName,
			"env":    getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
		}
	)
	if r.Method == "POST" { //deep ping
		checks := make(map[string]string)
		appendPing(checks, "redis", tsWaterReader.GetPinger("redis"))
		appendPing(checks, "ts", tsWaterReader.GetPinger("timescale"))
		appendPing(checks, "ddb", tsWaterReader.GetPinger("dynamo"))
		appendPing(checks, "kafka", kfWaterConsumer.kaf.Ping)
		appendPing(checks, "s3", s3Handler.s3Reader.Ping)
		appendPing(checks, "presence", presencePing)
		rv["checks"] = checks
		for _, v := range checks {
			if v != "OK" {
				rv["status"] = "Unavailable"
				code = 503 //unavailable
			}
		}
	}
	rv["took"] = fmt.Sprint(time.Since(started))
	httpWrite(w, code, rv, started)
}

func appendPing(m map[string]string, name string, pinger func() error) {
	if e := pinger(); e != nil {
		m[name] = e.Error()
	} else {
		m[name] = "OK"
	}
}

type HttpErr struct {
	Code    int    `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	IsJSON  bool   `json:"-"`
}

func (e *HttpErr) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

func httpError(w http.ResponseWriter, code int, msg string, err error) *HttpErr {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)

	rv := HttpErr{
		Code:    code,
		Message: msg,
	}
	if err != nil {
		logWarn("httpError: %v %v | %v", code, msg, err)
	} else {
		logDebug("httpError: %v %v", code, msg)
	}
	js, _ := json.Marshal(rv)
	_, _ = w.Write(js)
	return &rv
}

func httpReadBody(w http.ResponseWriter, r *http.Request, v interface{}) *HttpErr {
	if r.Body == nil || r.ContentLength <= 0 {
		return httpError(w, 400, "empty body", nil)
	}
	defer r.Body.Close()

	bodyBytes, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return httpError(w, 400, "unable to read data", err)
	}
	logTrace("%v %v => %v", r.Method, r.URL.Path, string(bodyBytes))

	err = json.Unmarshal(bodyBytes, &v)
	if err != nil {
		return httpError(w, 400, "unable to parse data", err)
	}
	return nil
}

func httpWrite(w http.ResponseWriter, code int, item interface{}, startTime time.Time) {
	var rvJson []byte
	if item != nil {
		j, err := json.Marshal(item)
		if err != nil {
			logError("error serializing object to json %v", item)
			httpError(w, 500, "unable to serialize response", err)
			return
		}
		rvJson = j
	}

	//logTrace("HTTP RESPONSE %v => %v", code, string(rvJson))
	elapsed := time.Now().Sub(startTime).Seconds() * 1000
	w.Header().Set("x-elapsed-ms", fmt.Sprintf("%.3f", elapsed))
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	if len(rvJson) > 0 {
		_, _ = w.Write(rvJson)
	}
}

// poor-man middle ware in functional decorator pattern
func httpMidWareWithAuthDec(f http.HandlerFunc, basicAuthCred map[string]string) http.HandlerFunc {
	return httpMidWareDec(basicAuth(f, basicAuthCred))
}

func httpMidWareDec(f http.HandlerFunc) http.HandlerFunc {
	return panicRecover(cors(f))
}

func cors(f http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Headers", "accept, content-type")
		w.Header().Set("Access-Control-Allow-Methods", "*")
		w.Header().Set("Access-Control-Allow-Origin", "*")
		if r.Method == http.MethodOptions {
			return // empty body, nothing else to do
		}
		f(w, r)
		return
	}
}

func basicAuth(f http.HandlerFunc, allowCreds map[string]string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if len(allowCreds) == 0 {
			f(w, r) //bypass check if there are no credentials to check
			return
		}

		auth := strings.SplitN(r.Header.Get("Authorization"), " ", 2)
		if len(auth) != 2 || auth[0] != "Basic" {
			httpError(w, 401, "Authorization Missing or Invalid", nil)
			return
		}
		payload, _ := base64.StdEncoding.DecodeString(auth[1])
		pair := strings.SplitN(string(payload), ":", 2)
		if len(pair) == 2 {
			un := pair[0]
			if pwd, ok := allowCreds[un]; ok && pwd == pair[1] {
				f(w, r) //check OK
				return
			}
		}
		httpError(w, 403, "Authorization Failed", nil)
		return
	}
}

func panicRecover(h http.HandlerFunc) http.HandlerFunc {
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
