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

	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/commons/validator"
	instana "github.com/instana/go-sensor"
	ot "github.com/opentracing/opentracing-go"

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

type WebServer struct {
	router     *gin.Engine
	httpSvr    *http.Server
	instana    *instana.Sensor
	validate   *validator.Validator
	closers    []ICloser
	state      int32
	log        *utils.Logger
	logIgnores map[string]string
}

type ICloser interface {
	Open()
	Close()
}

func CreateWebServer(validator *validator.Validator, log *utils.Logger, registerRoutes func(*WebServer), closers []ICloser) *WebServer {
	if log == nil {
		log = utils.DefaultLogger()
	}
	port, e := strconv.ParseInt(utils.GetEnvOrDefault(ENVVAR_HTTP_PORT, HTTP_DEFAULT_PORT), 10, 32)
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
	ws := WebServer{
		log:      log.CloneAsChild("ws"),
		router:   gin.New(),
		closers:  closers,
		validate: validator,
	}
	ws.presetLogIgnores()
	ws.router.Use(gin.Recovery()) //should be the outer most middleware for best crash protection
	if ws.log.IsDebug {
		ws.router.Use(gin.LoggerWithFormatter(ws.logColor))
	} else {
		ws.router.Use(gin.LoggerWithFormatter(ws.logLine))
		ws.initInstana()
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
	registerRoutes(&ws) // register routes
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
			utils.LogError(err.Error())
		}
	}()
	for i, c := range ws.closers {
		if c == nil {
			continue
		}
		go func(worker ICloser, n int) {
			defer utils.PanicRecover(ws.log, "Open closer %v", n)
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
	defer utils.PanicRecover(ws.log, "tryClose %v", n)
	ws.log.Trace("tryClosing %v", n)
	c.Close()
}

func (ws *WebServer) initInstana() *WebServer {
	var deltaName = AppName()
	sn := strings.TrimSpace(utils.GetEnvOrDefault("INSTANA_SERVICE_NAME", deltaName))
	// Get environment
	var env = strings.TrimSpace(utils.GetEnvOrDefault("ENVIRONMENT", utils.GetEnvOrDefault("ENV", "")))
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

func (ws *WebServer) presetLogIgnores() {
	ws.logIgnores = make(map[string]string)
	for _, ip := range strings.Split(utils.GetEnvOrDefault(ENVVAR_HTTP_LOG_PATH_IGNORES, ""), "|") {
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
	statusColor := utils.LL_DebugColor
	status := "DEBUG"
	if param.StatusCode >= 500 {
		statusColor = utils.LL_ErrorColor
		status = "ERROR"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 1 {
		statusColor = utils.LL_WarningColor
		status = "WARN"
	} else if param.StatusCode <= 100 {
		statusColor = utils.LL_InfoColor
	}
	return fmt.Sprintf("%v%v%v %v%v %v%v %vms %v %v %v %v %v %v%v%v\n",
		utils.LL_TraceColor,
		param.TimeStamp.Format("15:04:05"),
		utils.LL_ResetColor,
		statusColor,
		status,
		param.StatusCode,
		utils.LL_ResetColor,
		param.Latency.Milliseconds(),
		utils.LL_BgGray,
		param.Request.Method,
		param.Request.URL.Path,
		utils.LL_ResetColor,
		param.Request.Header,
		statusColor,
		param.ErrorMessage,
		utils.LL_ResetColor,
	)
}

func (ws *WebServer) logLine(param gin.LogFormatterParams) string {
	if !ws.canLog(param) {
		return ""
	}
	var status string
	if param.StatusCode >= 500 {
		status = "ERROR"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 1 {
		status = "WARN"
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
		param.Request.Header,
		param.ErrorMessage,
	)
}

func (ws *WebServer) Logger() *utils.Logger {
	return ws.log
}

func (ws *WebServer) Validator() *validator.Validator {
	return ws.validate
}

func (ws *WebServer) HttpError(c *gin.Context, code int, msg string, err error) error {
	ws.log.PushScope("HttpE")
	defer ws.log.PopScope()

	rv := utils.HttpErr{Code: code, Message: msg}
	if err != nil {
		rv.Trace = err.Error()
	}

	ll := utils.LL_WARN
	if code == 0 || code >= 500 {
		ll = utils.LL_ERROR
	} else if code < 400 {
		ll = utils.LL_NOTICE
	}
	ws.log.Log(ll, "HTTP %v | %v | %v", rv.Code, rv.Message, rv.Trace)
	c.JSON(code, rv)
	return &rv
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
		return ws.HttpError(c, 400, "Bad arguments", err)
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
		return ws.HttpError(c, 400, "Bad arguments", err)
	}
	return nil
}
