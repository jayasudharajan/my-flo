package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	instana "github.com/instana/go-sensor"
	"github.com/instana/go-sensor/instrumentation/instaecho"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"github.com/opentracing/opentracing-go"
	ot "github.com/opentracing/opentracing-go"
	"github.com/opentracing/opentracing-go/ext"
)

var _instana *instana.Sensor

// type timedFunctionMethod func()

func init() {
	initInstana()
}

func initInstana() {
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
	// ref: https://pkg.go.dev/github.com/instana/go-sensor/instrumentation/instaecho
	e := instaecho.New(_instana)

	return e
}

// creates a new subspan using passed in options
func MakeSpanWithOptions(ctx context.Context, name string, opts ...ot.StartSpanOption) ot.Span {
	tracer := _instana.Tracer()
	if ps, ok := instana.SpanFromContext(ctx); ok {
		tracer = ps.Tracer()
		opts = append(opts, ot.ChildOf(ps.Context()))
	}
	span := tracer.StartSpan(name, opts...)

	return span
}

// build a subspan for http calls
// ref http.route: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/http.md
// ref http.path_tpl: https://www.ibm.com/docs/en/instana-observability/current?topic=tracing-best-practices#http
func MakeSpanHttpClient(ctx context.Context, namePrefix, scheme, method, url, target, route, tpl string) ot.Span {
	tags := ot.Tags{
		"http.scheme":          scheme,
		string(ext.HTTPMethod): method,
		string(ext.HTTPUrl):    url,
		"http.target":          target,
	}
	if len(route) > 0 {
		tags["http.route"] = route
	}
	if len(tpl) > 0 {
		tags["http.path_tpl"] = tpl
	}

	opts := []ot.StartSpanOption{
		ext.SpanKindRPCClient,
		tags,
	}
	name := namePrefix + ": " + method + " " + url
	span := MakeSpanWithOptions(ctx, name, opts...)

	return span
}

// build a subspan for Kafka consumer calls
func MakeSpanKafkaConsumer(ctx context.Context, name, topic, consumerId, key string) ot.Span {
	tags := ot.Tags{
		"messaging.system":           "kafka",
		"messaging.destination":      topic,
		"messaging.destination_kind": "topic",
	}
	if len(consumerId) > 0 {
		tags["messaging.kafka.consumer_group"] = consumerId
	}
	if len(key) > 0 {
		tags["messaging.kafka.message_key"] = key
	}

	opts := []ot.StartSpanOption{
		ext.SpanKindConsumer,
		tags,
	}
	span := MakeSpanWithOptions(ctx, name, opts...)

	return span
}

// build a subspan for Kafka consumer calls
func MakeSpanMqttProducer(ctx context.Context, name, deviceId, topic string) ot.Span {
	opts := []ot.StartSpanOption{
		ext.SpanKindProducer,
		ot.Tags{
			"messaging.system":               "mqtt",
			"messaging.operation":            "publish",
			"messaging.destination":          topic,
			"messaging.destination_kind":     "topic",
			"messaging.destination.template": makeMqttTemplate(topic),
			"messaging.protocol":             "MQTT",
			"device_id":                      deviceId,
			"server.address":                 _mqttBrokerUrl,
		},
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

type someRoundTripper func(*http.Request) (*http.Response, error)

func (rt someRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	return rt(req)
}

func PanicWrapRoundTripper(name string, original http.RoundTripper) http.RoundTripper {
	return someRoundTripper(func(req *http.Request) (*http.Response, error) {
		defer func() {
			if r := recover(); r != nil {
				msg := fmt.Sprintf("%s: Caught Panic: %v", name, r)
				log.Error(msg)
			}
		}()

		return original.RoundTrip(req)
	})
}

func makeMqttTemplate(topic string) string {
	// for messaging.destination.template to group messages together
	// sample: "messaging.destination": "home/device/606405c117a8/v1/notifications-response/ack",
	//     to: "messaging.destination.template": "home/device/{device_id}/v1/notifications-response/ack",
	s := strings.Split(topic, "/")
	if len(s) > 2 {
		s[2] = "{device_id}"
	}
	return strings.Join(s, "/")
}

func InstaKafkaCtxExtract(name, topic string, headers *[]kafka.Header) (context.Context, ot.Span) {
	textmap := make(map[string]string)
	for _, h := range *headers {
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
		name+" "+"receive",
		ext.RPCServerOption(wireContext),
		ext.SpanKindConsumer,
		ot.Tags{
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
