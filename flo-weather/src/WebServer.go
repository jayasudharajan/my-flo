package main

import (
	"context"
	"encoding/json"

	//"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	instana "github.com/instana/go-sensor"
	ot "github.com/opentracing/opentracing-go"

	"github.com/gorilla/mux"

	"github.com/go-errors/errors"
	"github.com/go-playground/validator/v10"
	"github.com/gorilla/schema"
	_ "gitlab.com/flotechnologies/flo-weather/docs"
)

type WebServer struct {
	muxRouter    *mux.Router
	webServer    *http.Server
	Log          *Logger
	ctx          context.Context
	hostName     string
	port         int
	localDebug   bool
	payloadDebug bool
	instana      *instana.Sensor
	validate     *validator.Validate
	regExMap     sync.Map
	logPerf      bool
	statsMap     sync.Map
	StatsIgnore  sync.Map
	closers      []IOpenCloser
	state        int32 //0 not started/stopped, 1 already init, 2 open & running
}

type IOpenCloser interface {
	Open()
	Close()
}

const APP_NAME = "flo-weather"
const HTTP_DEFAULT_PORT = "8080"
const ENVVAR_HTTP_PORT = "FLO_HTTP_PORT"
const ENVVAR_LOG_PERF = "FLO_LOG_PERF"
const ENVVAR_LOG_PERF_IGNORE = "FLO_LOG_PERF_IGNORE"
const ENVVAR_DEBUG_PAYLOAD = "FLO_DEBUG_PAYLOAD"

func DefaultWebServerOrExit() *WebServer {
	log := DefaultLogger().SetName("WebSvr").PushScope("DefaultWebServerOrExit")
	defer log.PopScope()

	httpPortString := getEnvOrDefault(ENVVAR_HTTP_PORT, HTTP_DEFAULT_PORT)
	portInt, err := strconv.ParseInt(httpPortString, 10, 32)
	if err != nil {
		log.Fatal("Unable to parse: %v | %v", httpPortString, err.Error())
		signalExit()
	}
	if portInt <= 0 || portInt > 65535 {
		log.Fatal("HTTP port range is invalid: %v", portInt)
		signalExit()
	}
	return CreateWebServer(int(portInt), log)
}
func CreateWebServer(port int, log *Logger) *WebServer {
	w := WebServer{
		port:         port,
		Log:          log,
		ctx:          context.Background(),
		localDebug:   strings.ToLower(getEnvOrDefault(ENVVAR_LOCAL_DEBUG, "")) == "true",
		logPerf:      strings.ToLower(getEnvOrDefault(ENVVAR_LOG_PERF, "")) == "true",
		validate:     validator.New(),
		StatsIgnore:  sync.Map{},
		payloadDebug: strings.ToLower(getEnvOrDefault(ENVVAR_DEBUG_PAYLOAD, "")) == "true",
		closers:      make([]IOpenCloser, 0, 1),
	}
	if !w.localDebug {
		w.initInstana()
	}
	ig := getEnvOrDefault(ENVVAR_LOG_PERF_IGNORE, "")
	if ignores := strings.Split(ig, "|"); len(ignores) != 0 {
		for _, s := range ignores {
			if s != "" {
				w.StatsIgnore.LoadOrStore(s, "")
			}
		}
	}
	w.hostName = w.getHostName()
	return w.initValidators()
}

func (w *WebServer) initValidators() *WebServer { //register custom validators, SEE: https://www.works-hub.com/learn/how-should-we-prepare-for-evil-inputs-in-golang-44611
	w.Log.PushScope("initValidators")
	defer w.Log.PopScope()
	w.validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		arr := strings.SplitN(fld.Tag.Get("json"), ",", 2)
		if len(arr) == 0 {
			return ""
		}
		name := arr[0]
		if name == "-" {
			return ""
		}
		return name
	})
	var err error
	err = w.validate.RegisterValidation("datetime", func(fl validator.FieldLevel) bool {
		val := fl.Field().String()
		if val == "<time.Time Value>" { //fix bug w/ validator when type is time.Time
			return true
		}
		ps := fl.Param()
		dt, err := time.Parse(ps, val)
		return err != nil && dt.After(time.Unix(0, 0))
	})
	w.Log.IfError(err)

	err = w.validate.RegisterValidation("regex", func(fl validator.FieldLevel) bool {
		ps := fl.Param()
		val := fl.Field().String()
		if rev, ok := w.regExMap.Load(ps); ok {
			re := rev.(*regexp.Regexp)
			return re.MatchString(val)
		} else {
			re := regexp.MustCompile(ps)
			w.regExMap.Store(ps, re)
			return re.MatchString(val)
		}
	})
	w.Log.IfError(err)
	return w
}

func (ws *WebServer) initInstana() *WebServer {
	var deltaName = APP_NAME
	sn := strings.TrimSpace(getEnvOrDefault("INSTANA_SERVICE_NAME", deltaName))
	// Get environment
	var env = strings.TrimSpace(getEnvOrDefault("ENVIRONMENT", getEnvOrDefault("ENV", "")))
	// If INSTANA_SERVICE_NAME is not set and we have ENV set, see which one it is
	if deltaName == sn && len(env) > 0 {
		// If we are NOT prod/production, then append suffix
		if !strings.EqualFold(env, "prod") && !strings.EqualFold(env, "production") {
			sn = deltaName + "-" + strings.ToLower(env)
		}
	}
	ws.instana = instana.NewSensor(sn)
	// Initialize the Open Tracing. Do not log anything other than WARN/ERRORS. Logz.io and Kibana logs from stdio.
	ot.InitGlobalTracer(instana.NewTracerWithOptions(&instana.Options{
		Service:  sn,
		LogLevel: instana.Warn}))
	return ws
}

func (_ *WebServer) getHostName() string {
	rv, _ := os.Hostname()
	if len(rv) == 0 {
		rv = "unknown"
	}
	// The destination does not need to exist because it is UDP, this is a 'dummy' to create a packet
	conn, err := net.Dial("udp", "8.8.8.8:53")
	if err != nil {
		return rv + "/0.0.0.0"
	}
	defer conn.Close()

	addr := conn.LocalAddr() // Retrieve the local IP that was used for sending data
	if addr == nil {
		return rv + "/0.0.0.0"
	} else {
		return rv + "/" + addr.(*net.UDPAddr).IP.String()
	}
}

func (w *WebServer) State() (int32, string) {
	if w == nil {
		return -1, ""
	}
	st := atomic.LoadInt32(&w.state)
	return st, w.StateName(st)
}

func (w *WebServer) StateName(st int32) string {
	if w == nil {
		return ""
	}
	switch st {
	case 1:
		return "Initialized"
	case 2:
		return "Running"
	default:
		return "Stopped"
	}
}

//can be called multiple time to register multiple custom routes but only when server is not running
func (w *WebServer) ConfigRoutes(cfgRoute func(router *mux.Router)) *WebServer {
	if w == nil {
		return w
	}
	w.Log.PushScope("CfgRoutes")
	defer w.Log.PopScope()
	if atomic.CompareAndSwapInt32(&w.state, 0, 1) { //do this only on initial init
		w.muxRouter = mux.NewRouter()
		w.muxRouter.Handle("/", w.TryHandle(w.DefaultPingHandler)).Methods("GET")
	}
	if st, stName := w.State(); st == 1 || st == 0 { //only if not running
		if cfgRoute == nil {
			return w
		}
		cfgRoute(w.muxRouter)
	} else {
		w.Log.Notice("can't register, service is already %v", stName)
	}
	return w
}

func (ws *WebServer) Handle(path string, handler func(w http.ResponseWriter, r *http.Request), methods ...string) *WebServer {
	if ws.muxRouter == nil {
		ws.ConfigRoutes(nil)
	}
	ws.muxRouter.Handle(path, ws.TryHandle(handler)).Methods(methods...)
	return ws
}

func (ws *WebServer) HandleTrace(path string, handler func(w http.ResponseWriter, r *http.Request), methods ...string) *WebServer {
	if ws.instana != nil {
		return ws.Handle(path, ws.instana.TracingHandler(path, handler), methods...)
	} else {
		return ws.Handle(path, handler, methods...)
	}
}

func (w *WebServer) Open(blocking bool) *WebServer {
	if w == nil {
		return w
	}
	w.ConfigRoutes(nil)
	if !atomic.CompareAndSwapInt32(&w.state, 1, 2) {
		_, st := w.State()
		w.Log.Notice("Open: can't, already %v", st)
		return w
	}

	// Create web server instance
	w.webServer = &http.Server{
		Addr: fmt.Sprintf("0.0.0.0:%v", w.port),
		// Good practice to set timeouts to avoid Slow-loris attacks.
		WriteTimeout: time.Second * 15,
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      w.muxRouter, // Pass our instance of gorilla/mux in.
	}
	for _, o := range w.closers {
		if o != nil {
			go o.Open()
		}
	}
	if blocking {
		w.waitForRequests()
	} else {
		go w.waitForRequests()
	}
	return w
}

func (w *WebServer) waitForRequests() {
	w.Log.Notice("Starting HTTP Api on port %v", w.port)
	e := w.webServer.ListenAndServe()
	w.Log.IfWarn(e)
}

func (w *WebServer) RegisterOpenCloser(c IOpenCloser) {
	if w != nil && c != nil {
		if st, n := w.State(); st == 0 || st == 1 {
			w.closers = append(w.closers, c)
		} else {
			w.Log.Notice("RegisterOpenCloser: can't, service %v", n)
		}
	}
}

func (w *WebServer) Close() {
	if w == nil {
		return
	}
	if !atomic.CompareAndSwapInt32(&w.state, 2, 0) {
		_, n := w.State()
		w.Log.Notice("Close: can't, service %v", n)
		return
	}
	for _, c := range w.closers {
		if c != nil {
			c.Close()
		}
	}
	// Create a deadline to wait for.
	wait := time.Duration(5 * time.Second)
	ctx, cancel := context.WithTimeout(w.ctx, wait)
	defer cancel()

	err := w.webServer.Shutdown(ctx)
	w.Log.IfErrorF(err, "Close: Stop")
}

// SEE: https://stackoverflow.com/questions/28745648/global-recover-handler-for-golang-http-panic
func (ws *WebServer) TryHandle(handler func(w http.ResponseWriter, r *http.Request)) http.Handler {
	if ws.logPerf {
		return ws.perfLog(ws.PanicRecover(http.HandlerFunc(handler)))
	} else {
		return ws.PanicRecover(http.HandlerFunc(handler))
	}
}

var CLEAN_HEADER = []string{
	"Authorization",
	"Cookie",
	"Cookie2",
	"Accept",
	"Accept-Encoding",
	"Connection",
	"Content-Type",
}

func (ws *WebServer) cleanHeader(h http.Header) http.Header {
	if h != nil {
		for _, n := range CLEAN_HEADER {
			h.Del(n)
		}
	}
	return h
}

func (ws *WebServer) perfLog(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		if ws.payloadDebug {
			if _, ok := ws.StatsIgnore.Load(r.URL.Path); !ok {
				ws.Log.Debug("REQ_START %v %v | %v", r.Method, r.URL, ws.cleanHeader(r.Header))
			}
		}
		h.ServeHTTP(w, r)
		ws.incTimeAndLog(r, start)
	})
}

type Pref struct {
	count      int64
	ms         int64
	lastFlushS int64
}

func (p *Pref) fLushStatsAvg() Pref {
	if p == nil {
		return Pref{}
	}
	c, m, f := atomic.SwapInt64(&p.count, 0), atomic.SwapInt64(&p.ms, 0), atomic.SwapInt64(&p.lastFlushS, time.Now().UTC().Unix())
	var r int64 = 0
	if c > 0 {
		r = m / c
	}
	return Pref{
		count:      c,
		ms:         r,
		lastFlushS: time.Now().UTC().Unix() - f,
	}
}

func (ws *WebServer) incTimeAndLog(r *http.Request, start time.Time) {
	if vi, ok := ws.StatsIgnore.Load(r.URL.Path); ok && vi != nil {
		if verbs := fmt.Sprint(vi); len(verbs) == 0 {
			return
		} else if !strings.Contains(verbs, r.Method) {
			return
		}
	}
	var nc = &Pref{count: 1}
	cr, loaded := ws.statsMap.LoadOrStore(r.URL.Path, nc)
	var took int64 = time.Since(start).Milliseconds()
	if loaded {
		cc := cr.(*Pref)
		sumCount := atomic.AddInt64(&cc.count, 1)
		atomic.AddInt64(&cc.ms, took)
		lastFsh := atomic.LoadInt64(&cc.lastFlushS)
		if sumCount > 5_000 || time.Now().UTC().Unix()-lastFsh > 5*60 {
			avg := cc.fLushStatsAvg()
			dur := time.Duration(avg.lastFlushS) * time.Second
			ll := LL_INFO
			if avg.count > 10 {
				if avg.ms > 500 {
					ll = LL_NOTICE
				} else if avg.ms > 1000 {
					ll = LL_WARN
				}
			}
			ws.Log.Log(ll, "STATS %v requests AVG %vms within %v", avg.count, avg.ms, fmtDuration(dur))
		}
	} else {
		atomic.AddInt64(&nc.lastFlushS, time.Now().UTC().Unix())
		atomic.AddInt64(&nc.ms, took)
	}
	ll := LL_DEBUG
	fm := "%vms %v %v | %v"
	if took >= 1_000 {
		ll = LL_NOTICE
		fm = "SLOW " + fm
	} else if took >= 500 {
		ll = LL_INFO
	}
	ws.Log.Log(ll, fm, took, r.Method, r.URL, ws.cleanHeader(r.Header))
}

func (ws *WebServer) PanicRecover(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		defer func() {
			r := recover()
			if r != nil {
				level := LL_WARN
				var err error
				switch t := r.(type) {
				case string:
					err = errors.New(t)
				case error:
					level = LL_ERROR
					err = t
					e := errors.Wrap(err, 2)
					err = e
					defer ws.Log.Error(e.ErrorStack())
				default:
					err = errors.New("Unknown error")
				}
				defer ws.Log.Log(level, "%v %v | %v | => %v", req.Method, req.URL, req.Header, err.Error())
				ws.HttpError(w, 503, "PanicRecover", err)
			}
		}()
		h.ServeHTTP(w, req)
	})
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
func (ws *WebServer) DefaultPingHandler(w http.ResponseWriter, r *http.Request) {
	rv := map[string]interface{}{
		"date":   time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":    APP_NAME,
		"status": "ok",
		"host":   ws.hostName,
		"env":    getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
		"uptime": int64(time.Now().Sub(_start).Seconds()),
	}
	commit := getEnvOrDefault("COMMITSHA", "")
	if commit != "" {
		rv["commit"] = commit
	}
	commitTime := getEnvOrDefault("COMMITTIME", "")
	if commitTime != "" {
		rv["commitTime"] = commitTime
	}
	ws.HttpWrite(w, 200, rv)
}

type HttpErr struct {
	Code    int    `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	Trace   string `json:"developer,omitempty"`
}

func (e *HttpErr) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

func (ws *WebServer) HttpError(w http.ResponseWriter, code int, msg string, err error) *HttpErr {
	ws.Log.PushScope("HttpE")
	defer ws.Log.PopScope()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)

	rv := HttpErr{
		Code:    code,
		Message: msg,
	}
	if err != nil {
		rv.Trace = err.Error()
		if code == 503 {
			ws.Log.Error("%v %v | %v", code, msg, rv.Trace)
		} else {
			ws.Log.Warn("%v %v | %v", code, msg, rv.Trace)
		}
	} else {
		ws.Log.Debug("%v %v", code, msg)
	}
	if ws.payloadDebug {
		js, e := json.Marshal(rv)
		ws.Log.IfError(e)
		_, e = w.Write(js)
	} else {
		e := json.NewEncoder(w).Encode(rv)
		ws.Log.IfError(e)
	}
	return &rv
}

func (ws *WebServer) HttpWrite(w http.ResponseWriter, code int, item interface{}) *HttpErr {
	ws.Log.PushScope("HttpW")
	defer ws.Log.PopScope()

	if ws.payloadDebug {
		var rvJson []byte
		if item != nil {
			j, err := json.Marshal(item)
			if err != nil {
				return ws.HttpError(w, 500, "Can't serialize response", err)
			}
			rvJson = j
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(code)
		if len(rvJson) > 0 {
			_, e := w.Write(rvJson)
			ws.Log.IfError(e)
		}
	} else {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(code)
		e := json.NewEncoder(w).Encode(item)
		ws.Log.IfError(e)
	}
	return nil
}

func (ws *WebServer) HttpReadBody(w http.ResponseWriter, r *http.Request, v interface{}) *HttpErr {
	ws.Log.PushScope("HttpRB")
	defer ws.Log.PopScope()

	if r.Body == nil || r.ContentLength <= 0 {
		return ws.HttpError(w, 400, "Empty body", nil)
	}
	defer r.Body.Close()

	var err error
	if ws.payloadDebug {
		var bodyBytes []byte
		bodyBytes, err = ioutil.ReadAll(r.Body)
		if err != nil {
			return ws.HttpError(w, 400, "Can't read data", err)
		}
		ws.Log.Trace("%v %v | %v", r.Method, r.URL.Path, string(bodyBytes))
		err = json.Unmarshal(bodyBytes, &v)
	} else {
		err = json.NewDecoder(r.Body).Decode(&v) //quicker than marshaling to str
	}
	if err != nil {
		return ws.HttpError(w, 400, "Can't parse body", err)
	}
	if err := ws.validate.Struct(v); err != nil {
		return ws.HttpError(w, 400, "Bad arguments", err)
	}
	return nil
}

func (ws *WebServer) HttpReadQuery(w http.ResponseWriter, r *http.Request, v interface{}) *HttpErr {
	ws.Log.PushScope("HttpRQ")
	defer ws.Log.PopScope()

	decoder := schema.NewDecoder()
	decoder.IgnoreUnknownKeys(true)
	if err := decoder.Decode(v, r.URL.Query()); err != nil {
		return ws.HttpError(w, 400, "Can't parse query", err)
	}
	if err := ws.validate.Struct(v); err != nil {
		return ws.HttpError(w, 400, "Bad arguments", err)
	}
	return nil
}
