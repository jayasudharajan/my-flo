package main

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
	instana "github.com/instana/go-sensor"
	ot "github.com/opentracing/opentracing-go"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

const (
	httpDefaultPort = "8080"
	envVarHttpPort  = "FLO_HTTP_PORT"
	timeFmtNoMs     = "2006-01-02T15:04:05Z"
)

type WebServer interface {
	Start()
	Stop()
	GetEngine() *gin.Engine
}

type Resource interface {
	Open()
	Close()
}

type webServer struct {
	log       *Logger
	appInfo   *AppInfo
	router    *gin.Engine
	httpSvr   *http.Server
	instana   *instana.Sensor
	resources []Resource
	state     int32
}

func CreateWebServer(log *Logger, appInfo *AppInfo, registerRoutes func(WebServer), resources []Resource) WebServer {
	if log == nil {
		log = DefaultLogger()
	}
	port, e := strconv.ParseInt(getEnvOrDefault(envVarHttpPort, httpDefaultPort), 10, 32)
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
	ws := webServer{
		log:       log.CloneAsChild("ws"),
		appInfo:   appInfo,
		router:    gin.New(),
		resources: resources,
	}
	ws.router.Use(gin.Recovery()) //should be the outer most middleware for best crash protection
	if ws.log.isDebug {
		ws.router.Use(gin.LoggerWithFormatter(ws.logColor))
	} else {
		gin.SetMode(gin.ReleaseMode)
		ws.router.Use(gin.LoggerWithFormatter(ws.logLine))
		ws.initInstana()
	}

	ws.router.NoRoute(ws.noRoute)
	ws.router.NoMethod(ws.noMethod)
	ws.router.GET("/docs", func(c *gin.Context) {
		c.Redirect(http.StatusFound, "/swagger/index.html")
	})
	ws.router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler, ginSwagger.URL("/swagger/doc.json")))
	ws.httpSvr = &http.Server{
		Addr:         fmt.Sprintf("0.0.0.0:%v", port),
		WriteTimeout: time.Second * 15, // Good practice to set timeouts to avoid Slowloris attacks.
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      ws.router,
	}
	registerRoutes(&ws)
	return &ws
}

func (ws *webServer) Start() {
	ws.log.Notice("Open: starting web server @ %v", ws.httpSvr.Addr)
	// Run our server in a goroutine (separate thread) so that it doesn't block.
	go func() {
		if err := ws.httpSvr.ListenAndServe(); err != nil {
			if err == http.ErrServerClosed {
				ws.log.Info("server successfully closed.")
			} else {
				ws.log.Error(err.Error())
			}
		}
	}()
	for i, r := range ws.resources {
		if r == nil {
			continue
		}
		go func(resource Resource, n int) {
			defer panicRecover(ws.log, "Open: #%v %p", n, resource)
			ws.log.Debug("Open: #%v %p %s", n, resource, typeName(resource))
			resource.Open()
		}(r, i)
	}
}

func (ws *webServer) Stop() {
	if !atomic.CompareAndSwapInt32(&ws.state, 0, 1) {
		return
	}
	ws.log.PushScope("Stop")
	defer ws.log.PopScope()

	ws.log.Info("begin")
	// Create a deadline to wait for.
	wait := time.Second * 3
	ctx, cancel := context.WithTimeout(context.Background(), wait)
	defer cancel()

	if err := ws.httpSvr.Shutdown(ctx); err != nil {
		ws.log.IfWarn(err)
	}
	ws.log.Info("closing %d resources", len(ws.resources))
	for i, c := range ws.resources {
		ws.tryClose(c, i)
	}
	ws.log.Info("done")
}

func (ws *webServer) GetEngine() *gin.Engine {
	return ws.router
}

func (ws *webServer) tryClose(r Resource, n int) {
	if r == nil {
		return
	}
	defer panicRecover(ws.log, "tryClose #%v %p", n, r)
	ws.log.Debug("tryClose #%v %p %s", n, r, typeName(r))
	r.Close()
}

func (ws *webServer) initInstana() {
	deltaName := ws.appInfo.appName
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
}

func (ws *webServer) noRoute(c *gin.Context) {
	ws.HttpError(c, 404, "Path Not Found", nil)
}

func (ws *webServer) noMethod(c *gin.Context) {
	ws.HttpError(c, 405, "Method Missing", nil)
}

func (ws *webServer) canLog(param gin.LogFormatterParams) bool {
	if param.StatusCode < 1 || param.StatusCode >= 300 {
		return true
	}
	return false
}

func (ws *webServer) logColor(param gin.LogFormatterParams) string {
	if !ws.canLog(param) {
		return ""
	}
	statusColor := LL_DebugColor
	status := "DEBUG"
	if param.StatusCode >= 500 {
		statusColor = LL_ErrorColor
		status = "ERROR"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 1 {
		statusColor = LL_WarningColor
		status = "WARN"
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
		param.Request.Header,
		statusColor,
		param.ErrorMessage,
		LL_ResetColor,
	)
}

func (ws *webServer) logLine(param gin.LogFormatterParams) string {
	if !ws.canLog(param) {
		return ""
	}
	var status string
	if param.StatusCode >= 500 {
		status = "ERROR"
	} else if param.StatusCode >= 400 || param.Latency.Seconds() > 2 {
		status = "WARN"
	} else {
		if param.Latency.Seconds() > 1 {
			status = "NOTICE"
		} else {
			status = "DEBUG"
		}
	}
	return fmt.Sprintf("%v %v %v %vms %v %v %v %v\n",
		param.TimeStamp.Format(timeFmtNoMs),
		status,
		param.StatusCode,
		param.Latency.Milliseconds(),
		param.Request.Method,
		param.Request.URL.Path,
		param.Request.Header,
		param.ErrorMessage,
	)
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

func (ws *webServer) HttpError(c *gin.Context, code int, msg string, err error) error {
	ws.log.PushScope("HttpE")
	defer ws.log.PopScope()

	rv := HttpErr{Code: code, Message: msg}
	if err != nil {
		rv.Trace = err.Error()
	}

	ll := LL_WARN
	if code == 0 || code >= 500 {
		ll = LL_ERROR
	} else if code < 400 {
		ll = LL_NOTICE
	}
	ws.log.Log(ll, "HTTP %v | %v | %v", rv.Code, rv.Message, rv.Trace)
	c.JSON(code, rv)
	return &rv
}
