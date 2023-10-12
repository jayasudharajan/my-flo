package main

import (
	"context"
	"strings"

	instana "github.com/instana/go-otel-exporter"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

var _instana *instana.Exporter
var _tracerProvider *sdktrace.TracerProvider
var _tracer trace.Tracer

// setup instana exporter and _tracer
func init() {
	sn := strings.TrimSpace(getEnvOrDefault("INSTANA_SERVICE_NAME", "flo-notification-processor"))
	// Get environment
	var env = strings.TrimSpace(getEnvOrDefault("ENVIRONMENT", getEnvOrDefault("ENV", "")))
	// If INSTANA_SERVICE_NAME is not set and we have ENV set, see which one it is
	if len(env) > 0 {
		// If we are NOT prod/production, then append suffix
		if !strings.EqualFold(env, "prod") && !strings.EqualFold(env, "production") {
			sn = sn + "-" + strings.ToLower(env)
		}
	}
	_instana = instana.New()
	r := resource.NewSchemaless(
		attribute.String("service.name", sn),
	)
	_tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(_instana),
		sdktrace.WithResource(r),
	)
	otel.SetTracerProvider(_tracerProvider)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	_tracer = _tracerProvider.Tracer(sn)
}

func OtelSpanMqttProducer(ctx context.Context, name, topic string, attrs ...attribute.KeyValue) (context.Context, trace.Span) {
	newCtx, sp := _tracer.Start(ctx, name, trace.WithSpanKind(trace.SpanKindProducer))
	sp.SetAttributes(
		attribute.String("messaging.system", "mqtt"),
		attribute.String("messaging.operation", "publish"),
		attribute.String("messaging.address", topic),
		semconv.NetTransportTCP,
		attribute.String("server.address", _floMqttBroker),
		attribute.String("messaging.destination.kind", "topic"),
		attribute.String("messaging.destination", topic),
		attribute.String("messaging.destination.template", makeMqttTemplate(topic)),
	)
	sp.SetAttributes(attrs...)

	return newCtx, sp
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
