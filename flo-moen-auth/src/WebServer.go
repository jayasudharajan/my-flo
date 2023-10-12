package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	instana "github.com/instana/go-sensor"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/schema"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

const (
	HTTP_DEFAULT_PORT            = "8080"
	ENVVAR_HTTP_PORT             = "FLO_HTTP_PORT"
	ENVVAR_HTTP_LOG_PATH_IGNORES = "FLO_HTTP_LOG_PATH_IGNORES" //sample: FLO_HTTP_LOG_PATH_IGNORES=/ping|GET POST /queue|HEAD /something/something
)

// WebServer wraps gin framework for common web hosting tasks
type WebServer struct {
	svc        ServiceLocator
	router     *gin.Engine
	httpSvr    *http.Server
	instana    *instana.Sensor
	validate   *Validator
	closers    []ICloser
	state      int32
	log        *Logger
	logIgnores map[string]string
}

type ICloser interface {
	Open()
	Close()
}

func init() {

}

func CreateWebServer(sl ServiceLocator, registerRoutes func(*WebServer, ServiceLocator), closers func() []ICloser) *WebServer {
	sl = sl.Clone()
	var (
		log     = sl.LocateName("*Logger").(*Logger).SetName("Web")
		port, e = strconv.ParseInt(getEnvOrDefault(ENVVAR_HTTP_PORT, HTTP_DEFAULT_PORT), 10, 32)
	)
	sl.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		return log //return this instance logger instead
	})
	if e != nil {
		log.Fatal("CreateWebServer: http port %v", e.Error())
		return nil
	} else if port <= 0 || port > 65535 {
		log.Fatal("CreateWebServer: port range is invalid %v", port)
		return nil
	} else if registerRoutes == nil {
		log.Fatal("CreateWebServer: registerRoutes is nil")
		return nil
	}
	gin.SetMode(gin.ReleaseMode)
	ws := WebServer{
		svc:      sl,
		log:      log.CloneAsChild("ws"),
		router:   gin.New(),
		validate: sl.LocateName("*Validator").(*Validator),
	}
	ws.closers = closers()
	ws.presetLogIgnores()
	ws.router.Use(gin.Recovery()) //should be the outer most middleware for best crash protection
	if ws.log.isDebug {
		ws.router.Use(gin.LoggerWithFormatter(ws.logColor))
	} else {
		ws.router.Use(gin.LoggerWithFormatter(ws.logLine))
		ws.initInstana(sl)
	}

	ws.router.NoRoute(ws.noRoute)
	ws.router.NoMethod(ws.noMethod)
	ws.router.GET("/docs", func(c *gin.Context) { // Swagger Setup
		c.Redirect(http.StatusFound, "/swagger/index.html")
	})
	ws.router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler, ginSwagger.URL("/swagger/doc.json")))
	ws.httpSvr = &http.Server{ // Create web server instance
		Addr:         fmt.Sprintf("0.0.0.0:%v", port),
		WriteTimeout: time.Second * 15, // Good practice to set timeouts to avoid Slowloris attacks.
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      ws.router, // Pass our instance of gorilla/mux in.
	}
	registerRoutes(&ws, sl) // register routes
	return &ws
}

func (ws *WebServer) noRoute(c *gin.Context) {
	ws.HttpError(c, 404, "Path Not Found", nil)
}

func (ws *WebServer) noMethod(c *gin.Context) {
	ws.HttpError(c, 405, "Method Missing", nil)
}

func (ws *WebServer) Open() *WebServer {
	if ws == nil {
		return nil
	}
	ws.log.Debug("Opening %v...", len(ws.closers))
	// Run our server in a goroutine (separate thread) so that it doesn't block.
	go func() {
		ws.log.Notice("Open: Starting HTTP Api @ %v", ws.httpSvr.Addr)
		if err := ws.httpSvr.ListenAndServe(); err != nil {
			ws.log.Error(err.Error())
		}
	}()
	for i, c := range ws.closers {
		if c == nil {
			continue
		}
		go func(worker ICloser, n int) {
			defer panicRecover(ws.log, "Open closer %v", n)
			ws.log.Trace("Open Closer %v", n)
			worker.Open()
		}(c, i)
	}
	ws.log.Info("Opened")
	return ws
}

func (ws *WebServer) Close() {
	if ws == nil || !atomic.CompareAndSwapInt32(&ws.state, 0, 1) {
		return
	}
	ws.log.PushScope("Close")
	defer ws.log.PopScope()

	ws.log.Info("Begin")
	// Create a deadline to wait for.
	wait := time.Second * 3
	ctx, cancel := context.WithTimeout(context.Background(), wait)
	defer cancel()

	if err := ws.httpSvr.Shutdown(ctx); err != nil {
		ws.log.IfWarn(err)
	}
	for i, c := range ws.closers {
		ws.tryClose(c, i)
	}
	ws.log.Info("Done")
}

func (ws *WebServer) tryClose(c ICloser, n int) {
	if c == nil {
		return
	}
	defer panicRecover(ws.log, "tryClose %v", n)
	ws.log.Trace("tryClosing %v", n)
	c.Close()
}

func (ws *WebServer) initInstana(sl ServiceLocator) *WebServer {
	ws.instana = tracing.Instana

	// add additional middleware after Instana is initialized
	tracing.WrapInstagin(ws.instana, ws.router)

	return ws
}

func (ws *WebServer) presetLogIgnores() {
	ws.logIgnores = make(map[string]string)
	for _, ip := range strings.Split(getEnvOrDefault(ENVVAR_HTTP_LOG_PATH_IGNORES, ""), "|") {
		verbsPath := strings.Split(ip, " ")
		if vl := len(verbsPath); vl == 1 { //path only
			ws.logIgnores[ip] = ""
		} else if vl > 1 { //verbs & path
			ws.logIgnores[verbsPath[vl-1]] = strings.Join(verbsPath[0:vl-1], " ")
		}
	}
}

func (ws *WebServer) canLog(param gin.LogFormatterParams) bool {
	if param.StatusCode < 1 || param.StatusCode >= 300 {
		return true
	} else if verbs, ok := ws.logIgnores[param.Request.URL.Path]; ok {
		if verbs == "" {
			return false
		}
		return !strings.Contains(verbs, param.Method)
	}
	return true
}

func (ws *WebServer) logColor(param gin.LogFormatterParams) string {
	if !ws.canLog(param) {
		return ""
	}
	statusColor := LL_DebugColor
	status := "DEBUG"
	if param.StatusCode >= 500 {
		statusColor = LL_WarningColor
		status = "WARN"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 1 {
		statusColor = LL_NoticeColor
		status = "NOTICE"
	} else if param.StatusCode <= 100 {
		statusColor = LL_InfoColor
	}
	return fmt.Sprintf("%v%v%v %v%v %v%v %vms %v %v %v %v %v %v%v%v\n",
		LL_TraceColor,
		param.TimeStamp.Format("15:04:05"),
		LL_ResetColor,
		statusColor,
		status,
		param.StatusCode,
		LL_ResetColor,
		param.Latency.Milliseconds(),
		LL_BgGray,
		param.Request.Method,
		param.Request.URL.Path,
		LL_ResetColor,
		ws.cleanHeader(param.Request.Header),
		statusColor,
		param.ErrorMessage,
		LL_ResetColor,
	)
}

var CLEAN_HEADER = []string{
	AUTH_HEADER,
	"Cookie",
	"Cookie2",
	"Accept",
	"Accept-Encoding",
	"Connection",
	"Content-Type",
}

func (ws *WebServer) cleanHeader(h http.Header) http.Header {
	for _, n := range CLEAN_HEADER {
		h.Del(n)
	}
	return h
}

func (ws *WebServer) logLine(param gin.LogFormatterParams) string {
	if !ws.canLog(param) {
		return ""
	}
	var status string
	if param.StatusCode >= 500 {
		status = "WARN"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 1 {
		status = "NOTICE"
	} else {
		status = "DEBUG"
	}
	return fmt.Sprintf("%v %v %v %vms %v %v %v %v\n",
		param.TimeStamp.Format("2006-01-02T15:04:05Z"),
		status,
		param.StatusCode,
		param.Latency.Milliseconds(),
		param.Request.Method,
		param.Request.URL.Path,
		ws.cleanHeader(param.Request.Header),
		param.ErrorMessage,
	)
}

func (ws *WebServer) Logger() *Logger {
	return ws.log
}

func (ws *WebServer) Validator() *Validator {
	return ws.validate
}

type HttpErr struct {
	Code    int    `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	IsJSON  bool   `json:"isJSON,omitempty"`
	Trace   error  `json:"-"` //don't return
}

func (e *HttpErr) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

func (e HttpErr) String() string {
	return tryToJson(e)
}

func (ws *WebServer) HttpErrorResp(c *gin.Context, e error) {
	if he, ok := e.(*HttpErr); ok && he.Code >= 400 && he.Code < 500 {
		ws.HttpError(c, he.Code, he.Message, he.Trace)
	} else {
		ws.HttpError(c, 500, "Internal Error", e)
	}
}

func (ws *WebServer) HttpError(c *gin.Context, code int, msg string, err error) error {
	ws.log.PushScope("HttpE")
	defer ws.log.PopScope()

	rv := HttpErr{Code: code, Message: msg}
	if err != nil {
		rv.Trace = err
	}

	ll := LL_NOTICE
	if code == 0 || code >= 500 {
		ll = LL_ERROR
	} else if code < 400 {
		ll = LL_INFO
	}
	ws.log.Log(ll, "HTTP %v | %v | %v", rv.Code, rv.Message, rv.Trace)
	c.AbortWithStatusJSON(code, rv)
	return &rv
}

func (ws *WebServer) HttpEmpty(c *gin.Context, code int) {
	c.Data(code, gin.MIMEPlain, nil)
}

func (ws *WebServer) HttpReadBody(c *gin.Context, v interface{}) error {
	ws.log.PushScope("HttpRB")
	defer ws.log.PopScope()

	r := c.Request
	if isNil := r.Body == nil; isNil || r.ContentLength <= 0 {
		return ws.HttpError(c, 400, "Empty body", nil)
	} else if !isNil {
		defer r.Body.Close()
	}

	err := json.NewDecoder(r.Body).Decode(&v) //quicker than marshaling to str
	if err != nil {
		return ws.HttpError(c, 400, "Can't parse body", err)
	}
	if err := ws.validate.Struct(v); err != nil {
		return ws.HttpError(c, 400, err.Error(), nil)
	}
	return nil
}

func (ws *WebServer) HttpReadQuery(c *gin.Context, v interface{}) error {
	ws.log.PushScope("HttpRQ")
	defer ws.log.PopScope()

	decoder := schema.NewDecoder()
	decoder.IgnoreUnknownKeys(true)
	if err := decoder.Decode(v, c.Request.URL.Query()); err != nil {
		return ws.HttpError(c, 400, "Can't parse query", err)
	}
	if err := ws.validate.Struct(v); err != nil {
		//var fieldErrs []validator.FieldError = err.(validator.ValidationErrors)
		return ws.HttpError(c, 400, err.Error(), nil)
	}
	return nil
}
