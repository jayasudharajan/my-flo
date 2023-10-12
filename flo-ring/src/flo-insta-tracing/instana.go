package tracing

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-sdk-go/service/eventbridge"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	instana "github.com/instana/go-sensor"
	ot "github.com/opentracing/opentracing-go"
	"github.com/opentracing/opentracing-go/ext"
)

var (
	Instana        *instana.Sensor
	disableTracing = IsSetInstanaDisableFlag()
)

func SetDisableTracing(b bool) {
	disableTracing = b
}

func IsTracingDisabled() bool {
	return disableTracing
}

func IsSetInstanaDisableFlag() bool {
	var disable = false
	var err error
	instaTraceDisable := os.Getenv("INSTANA_TRACE_DISABLE")
	if len(instaTraceDisable) > 0 {
		disable, err = strconv.ParseBool(instaTraceDisable)
	}
	if err != nil {
		// Instana.Warn("malformed INSTANA_TRACE_DISABLE. Using default")
		disable = false
	}
	return disable
}

// StartTracing initialized the tracers using standardized environment variables for service name
func StartTracing(deltaName string) {
	if !IsTracingDisabled() {
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

		InitInstana(sn)
	}
}

// InitInstana initializes Instana go-sensor with a given service name
func InitInstana(sn string) *instana.Sensor {
	tracer := instana.NewTracerWithOptions(&instana.Options{
		Service:  sn,
		LogLevel: instana.Warn})

	Instana = instana.NewSensorWithTracer(tracer)

	// Initialize the Open Tracing. Do not log anything other than WARN/ERRORS. Logz.io and Kibana logs from stdio.
	ot.InitGlobalTracer(tracer)

	return Instana
}

// PanicWrapRoundTripper
type someRoundTripper func(*http.Request) (*http.Response, error)

func (rt someRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	return rt(req)
}

// do a panic wrap around a http.RoundTripper
func PanicWrapRoundTripper(name string, original http.RoundTripper) http.RoundTripper {
	return someRoundTripper(func(req *http.Request) (*http.Response, error) {
		defer func() {
			if r := recover(); r != nil {
				msg := fmt.Sprintf("%s: Caught Panic: %v", name, r)
				Instana.Warn(msg)
			}
		}()

		return original.RoundTrip(req)
	})
}

// InstaKafkaStartProducerSpan starts a span with kafka message information
//
//	 kafkaMessage = *tracing.InstaKafkaCtxInsert(ctx, &kafkaMessage)
//	 sp := tracing.InstaKafkaStartProducerSpan(ctx, &kafkaMessage, k.Servers)
//		if sp != nil {
//			defer sp.Finish()
//		}
//	 k.Producer.ProduceChannel() <- &kafkaMessage
func InstaKafkaStartProducerSpan(ctx context.Context, msg *kafka.Message, brokers string) ot.Span {
	switch sc, err := Instana.Tracer().Extract(ot.TextMap, ProducerMessageCarrier{msg}); err {
	case nil:
		return Instana.Tracer().StartSpan(
			"kafka",
			ext.SpanKindProducer,
			ot.ChildOf(sc),
			ot.Tags{
				"kafka.service": msg.TopicPartition.Topic,
				"kafka.access":  "send",
				"kafka.brokers": brokers,
			},
		)
	default:
		Instana.Warn("failed to extract span context from producer message headers: ", err)
	}

	return nil
}

// InstaKafkaCtxInsert injects trace context to message header
//
//	 kafkaMessage = *tracing.InstaKafkaCtxInsert(ctx, &kafkaMessage)
//	 sp := tracing.InstaKafkaStartProducerSpan(ctx, &kafkaMessage, k.Servers)
//		if sp != nil {
//			defer sp.Finish()
//		}
//	 k.Producer.ProduceChannel() <- &kafkaMessage
func InstaKafkaCtxInsert(ctx context.Context, msg *kafka.Message) *kafka.Message {
	pm := ProducerMessageWithSpanFromContext(ctx, msg)

	return pm
}

// InstaKafkaCtxExtractWithSpan extracts propagated context from kafka message header and start a new span
//
//	note: remember to sp.Finish()
func InstaKafkaCtxExtractWithSpan(msg *kafka.Message, brokers string) (context.Context, ot.Span) {
	wireContext, _ := SpanContextFromConsumerMessage(msg, Instana)

	// Create the span referring to the RPC client if available.
	// If wireContext == nil, a root span will be created.
	serverSpan := ot.StartSpan(
		"kafka",
		ot.ChildOf(wireContext),
		ext.RPCServerOption(wireContext),
		ext.SpanKindConsumer,
		ot.Tags{
			"kafka.service": *(msg.TopicPartition.Topic),
			"kafka.access":  "consume",
			"kafka.brokers": brokers,
		},
	)

	ctx := instana.ContextWithSpan(context.Background(), serverSpan)

	return ctx, serverSpan
}

type EBPublishInfo struct {
	RequestId     string
	MessageType   string
	MessageAction string
}

// InstaEBStartProducerSpan starts a span based on AWS Event Bridge event
//
//	sp := tracing.InstaEBStartProducerSpan(ctx, eb,
//	tracing.EBPublishInfo{
//			RequestId:     publishInput.RequestID,
//			MessageType:   publishInput.MessageType,
//			MessageAction: publishInput.MessageAction,
//	})
//	defer sp.Finish()
//	if results, err = c.client.PutEvents(&inp); err != nil {
func InstaEBStartProducerSpan(ctx context.Context, eb eventbridge.PutEventsRequestEntry, pi EBPublishInfo) ot.Span {
	return Instana.Tracer().StartSpan(
		"aws.eventbridge.entry",
		ext.SpanKindProducer,
		ot.ChildOf(ot.SpanFromContext(ctx).Context()),
		// tags modeled after https://github.com/instana/go-sensor/blob/main/instrumentation/instalambda/handler.go
		ot.Tags{
			"RequestID":     pi.RequestId,
			"MessageType":   pi.MessageType,
			"MessageAction": pi.MessageAction,
			"EventBusName":  eb.EventBusName,
			"Source":        eb.Source,
		},
	)
}
