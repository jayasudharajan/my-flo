package main

import (
	"strings"

	instana "github.com/instana/go-sensor"
	ot "github.com/opentracing/opentracing-go"
)

var _instana *instana.Sensor

type timedFunctionMethod func()

func init() {
	var deltaName = APP_NAME

	// Get environment
	var env = strings.TrimSpace(getEnvOrDefault("ENVIRONMENT", getEnvOrDefault("ENV", "")))

	// If we have ENV set see which one it is
	if len(env) > 0 {
		// If we are NOT prod/production, then append suffix
		if !strings.EqualFold(env, "prod") && !strings.EqualFold(env, "production") {
			deltaName = deltaName + "-" + strings.ToLower(env)
		}
	}

	// Initialize the Instana project
	_instana = instana.NewSensor(deltaName)

	// Initialize the Open Tracing. Do not log anything other than WARN/ERRORS. Logz.io and Kibana logs from stdio.
	ot.InitGlobalTracer(instana.NewTracerWithOptions(&instana.Options{
		Service:  deltaName,
		LogLevel: instana.Warn}))
}

func instanaMethodTimer(name string, method timedFunctionMethod) {
	if method == nil {
		return
	}

	if len(name) == 0 {
		method()
		return
	}

	funcSpan := ot.StartSpan(name)
	method()
	funcSpan.Finish()
}
