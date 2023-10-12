package main

import (
	"context"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	instana "github.com/instana/go-sensor"
	"github.com/instana/go-sensor/instrumentation/instaecho"
	"github.com/labstack/echo/v4"
	"github.com/opentracing/opentracing-go"
	ot "github.com/opentracing/opentracing-go"
	"github.com/opentracing/opentracing-go/ext"
)

var _instana *instana.Sensor

type timedFunctionMethod func()

func init() {
	var deltaName = APP_NAME
	var instanaServiceName = strings.TrimSpace(getEnvOrDefault("INSTANA_SERVICE_NAME", deltaName))

	// Get environment
	var env = strings.TrimSpace(getEnvOrDefault("ENVIRONMENT", getEnvOrDefault("ENV", "")))
	if strings.EqualFold(env, "local") {
		logNotice("Not registering with Instana")
		return
	}

	// If INSTANA_SERVICE_NAME is not set and we have ENV set, see which one it is
	if deltaName == instanaServiceName && len(env) > 0 {
		// If we are NOT prod/production, then append suffix
		if !strings.EqualFold(env, "prod") && !strings.EqualFold(env, "production") {
			instanaServiceName = deltaName + "-" + strings.ToLower(env)
		}
	}

	opts := instana.Options{
		Service:           instanaServiceName,
		LogLevel:          instana.Warn,
		EnableAutoProfile: true,
		Tracer: instana.TracerOptions{
			CollectableHTTPHeaders: []string{"x-request-id", "x-loadtest-id"},
		},
	}

	// ref: https://zhimin-wen.medium.com/golang-application-tracing-in-instana-ff47645fbff6
	instana.StartMetrics(&opts)

	var disable = false
	var err error
	instaTraceDisable := os.Getenv("INSTANA_TRACE_DISABLE")
	if len(instaTraceDisable) > 0 {
		disable, err = strconv.ParseBool(instaTraceDisable)
	}
	if err != nil {
		logError("malformed INSTANA_TRACE_DISABLE. Using default")
		disable = false
	}
	var tracer ot.Tracer
	if disable {
		tracer = ot.NoopTracer{}
	} else {
		tracer = instana.NewTracerWithOptions(&opts)
	}
	// Initialize Instana object
	_instana = instana.NewSensorWithTracer(tracer)
	// Initialize Open Tracing
	ot.SetGlobalTracer(tracer)
}

func NewInstaecho() *echo.Echo {
	e := instaecho.New(_instana)
	return e
}

// creates a new subspan using passed in options
//   - don't forget to sp.Finish()
func MakeSpanWithOptions(ctx context.Context, name string, opts ...ot.StartSpanOption) ot.Span {
	tracer := _instana.Tracer()
	if ps, ok := instana.SpanFromContext(ctx); ok {
		tracer = ps.Tracer()
		opts = append(opts, ot.ChildOf(ps.Context()))
	}
	span := tracer.StartSpan(name, opts...)

	return span
}

// build a subspan for Rpc calls
//   - don't forget to sp.Finish()
func MakeSpanRpcClient(ctx context.Context, namePrefix, host, call string) ot.Span {
	opts := []ot.StartSpanOption{
		ext.SpanKindRPCClient,
		ot.Tags{
			"rpc.host": host,
			"rpc.call": call,
		},
	}
	name := namePrefix + ": " + host + " " + call
	span := MakeSpanWithOptions(ctx, name, opts...)

	return span
}

// build a subspan for Kafka consumer calls
// to set span error:
//
//	sp.SetTag("kafka.error", err)
//	sp.LogFields(otlog.Error(err))
func MakeSpanKafkaConsumer(ctx context.Context, name, topic, brokers string) ot.Span {
	tags := ot.Tags{
		"kafka.service":              topic,
		"kafka.access":               "consume",
		"kafka.brokers":              brokers,
		"messaging.system":           "kafka",
		"messaging.destination":      topic,
		"messaging.destination_kind": "topic",
	}

	opts := []ot.StartSpanOption{
		ext.SpanKindConsumer,
		tags,
	}
	span := MakeSpanWithOptions(ctx, name, opts...)

	return span
}

// build a subspan for internal calls
func MakeSpanInternal(ctx context.Context, name string) ot.Span {
	opts := []ot.StartSpanOption{
		ot.Tags{
			string(ext.SpanKind): "intermediate",
		},
	}
	span := MakeSpanWithOptions(ctx, name, opts...)

	return span
}

// Extract trace information and return ctx and span
// to set span error:
//
//	sp.SetTag("kafka.error", err)
//	sp.LogFields(otlog.Error(err))
func InstaKafkaCtxExtract(topic, brokers string, headers []kafka.Header) (context.Context, ot.Span) {
	textmap := make(map[string]string)
	for _, h := range headers {
		s := strings.Split(h.String(), "=")
		textmap[s[0]] = s[1]
	}

	wireContext, err := opentracing.GlobalTracer().Extract(
		opentracing.TextMap,
		opentracing.TextMapCarrier(textmap))
	if err != nil {
		logWarn("InstaKafkaCtxExtract: %v", err)
	}

	// Create the span referring to the RPC client if available.
	// If wireContext == nil, a root span will be created.
	serverSpan := opentracing.StartSpan(
		"Kafka "+topic+" receive",
		// "kafka",
		ext.RPCServerOption(wireContext),
		ext.SpanKindConsumer,
		ot.Tags{
			"kafka.service":              topic,
			"kafka.access":               "consume",
			"kafka.brokers":              brokers,
			"messaging.system":           "kafka",
			"messaging.operation":        "receive",
			"messaging.destination":      topic,
			"messaging.destination_kind": "topic",
		},
	)

	ctx := opentracing.ContextWithSpan(context.Background(), serverSpan)

	return ctx, serverSpan
}

// func instanaMethodTimer(name string, method timedFunctionMethod) {
// 	if method == nil {
// 		return
// 	}

// 	if len(name) == 0 {
// 		method()
// 		return
// 	}

// 	funcSpan := ot.StartSpan(name)
// 	method()
// 	funcSpan.Finish()
// }

func timeMethod(funcName string, args ...interface{}) func() {
	start := time.Now()
	funcSpan := ot.StartSpan(APP_NAME + "." + funcName)

	return func() {
		logTrace("TIMING %s %.2f ms %v", funcName, time.Since(start).Seconds()*1000, args)
		funcSpan.Finish()
	}
}
