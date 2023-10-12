// (c) Copyright IBM Corp. 2021
// (c) Copyright Instana Inc. 2020

package tracing_test

import (
	"context"
	"os"
	"testing"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	instana "github.com/instana/go-sensor"
	"github.com/instana/go-sensor/w3ctrace"
	"github.com/opentracing/opentracing-go"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

var headerFormats = []string{"" /* tests the default behavior */, "binary", "string", "both"}

func TestProducerMessageWithSpan(t *testing.T) {
	for _, headerFormat := range headerFormats {
		os.Setenv(tracing.KafkaHeaderEnvVarKey, headerFormat)

		recorder := instana.NewTestRecorder()
		tracer := instana.NewTracerWithEverything(&instana.Options{}, recorder)

		topic := "test-topic"
		sp := tracer.StartSpan("test-span")
		pm := &kafka.Message{
			TopicPartition: kafka.TopicPartition{
				Topic: &topic,
			},
			Key:   []byte("key1"),
			Value: []byte("value1"),
			Headers: []kafka.Header{
				{Key: "headerKey1", Value: []byte("headerValue1")},
			},
		}
		pm = tracing.ProducerMessageWithSpan(pm, sp)

		sp.Finish()
		spans := recorder.GetQueuedSpans()
		require.Len(t, spans, 1)

		expected := []kafka.Header{
			{Key: "headerKey1", Value: []byte("headerValue1")},
		}

		if headerFormat == "both" || headerFormat == "binary" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldL, Value: []byte{0x01}},
				{
					Key: tracing.FieldC,
					Value: tracing.PackTraceContextHeader(
						instana.FormatLongID(spans[0].TraceIDHi, spans[0].TraceID),
						instana.FormatID(spans[0].SpanID),
					),
				},
			}...)
		}

		if headerFormat == "both" || headerFormat == "string" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldLS, Value: []byte("1")},
				{
					Key:   tracing.FieldT,
					Value: []byte("0000000000000000" + instana.FormatID(spans[0].TraceID)),
				},
				{
					Key:   tracing.FieldS,
					Value: []byte(instana.FormatID(spans[0].SpanID)),
				},
			}...)
		}
		isc, ok := sp.Context().(instana.SpanContext)
		assert.True(t, ok)
		expected = append(expected, kafka.Header{Key: w3ctrace.TraceParentHeader, Value: []byte(isc.W3CContext.RawParent)})

		assert.ElementsMatch(t, expected, pm.Headers)

		os.Unsetenv(tracing.KafkaHeaderEnvVarKey)
	}
}

func TestProducerMessageWithSpanFromContext(t *testing.T) {
	for _, headerFormat := range headerFormats {
		os.Setenv(tracing.KafkaHeaderEnvVarKey, headerFormat)

		recorder := instana.NewTestRecorder()
		tracer := instana.NewTracerWithEverything(&instana.Options{}, recorder)

		sp := tracer.StartSpan("test-span")
		ctx := instana.ContextWithSpan(context.Background(), sp)

		topic := "test-topic"
		pm := tracing.ProducerMessageWithSpanFromContext(ctx, &kafka.Message{
			TopicPartition: kafka.TopicPartition{
				Topic: &topic,
			},
			Key:   []byte("key1"),
			Value: []byte("value1"),
			Headers: []kafka.Header{
				{Key: "headerKey1", Value: []byte("headerValue1")},
			},
		})
		sp.Finish()

		spans := recorder.GetQueuedSpans()
		require.Len(t, spans, 1)

		expected := []kafka.Header{
			{Key: "headerKey1", Value: []byte("headerValue1")},
		}

		if headerFormat == "both" || headerFormat == "binary" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldL, Value: []byte{0x01}},
				{
					Key: tracing.FieldC,
					Value: tracing.PackTraceContextHeader(
						instana.FormatLongID(spans[0].TraceIDHi, spans[0].TraceID),
						instana.FormatID(spans[0].SpanID),
					),
				},
			}...)
		}

		if headerFormat == "both" || headerFormat == "string" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldLS, Value: []byte("1")},
				{
					Key:   tracing.FieldT,
					Value: []byte("0000000000000000" + instana.FormatID(spans[0].TraceID)),
				},
				{
					Key:   tracing.FieldS,
					Value: []byte(instana.FormatID(spans[0].SpanID)),
				},
			}...)
		}
		isc, ok := sp.Context().(instana.SpanContext)
		assert.True(t, ok)
		expected = append(expected, kafka.Header{Key: w3ctrace.TraceParentHeader, Value: []byte(isc.W3CContext.RawParent)})

		assert.ElementsMatch(t, expected, pm.Headers)

		os.Unsetenv(tracing.KafkaHeaderEnvVarKey)
	}
}

func TestProducerMessageWithSpanFromContext_W3c(t *testing.T) {
	for _, headerFormat := range headerFormats {
		os.Setenv(tracing.KafkaHeaderEnvVarKey, headerFormat)

		recorder := instana.NewTestRecorder()
		tracer := instana.NewTracerWithEverything(&instana.Options{}, recorder)

		isc := instana.SpanContext{
			W3CContext: w3ctrace.Context{
				RawParent: "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
				RawState:  "vendor1=90210",
			},
			Baggage: make(map[string]string),
		}

		sp := tracer.StartSpan("test-span", opentracing.ChildOf(isc))
		ctx := instana.ContextWithSpan(context.Background(), sp)

		topic := "test-topic"
		pm := tracing.ProducerMessageWithSpanFromContext(ctx, &kafka.Message{
			TopicPartition: kafka.TopicPartition{
				Topic: &topic,
			},
			Key:   []byte("key1"),
			Value: []byte("value1"),
			Headers: []kafka.Header{
				{Key: "headerKey1", Value: []byte("headerValue1")},
			},
		})
		sp.Finish()

		spans := recorder.GetQueuedSpans()
		require.Len(t, spans, 1)

		expected := []kafka.Header{
			{Key: "headerKey1", Value: []byte("headerValue1")},
		}

		if headerFormat == "both" || headerFormat == "binary" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldL, Value: []byte{0x01}},
				{
					Key: tracing.FieldC,
					Value: tracing.PackTraceContextHeader(
						instana.FormatLongID(spans[0].TraceIDHi, spans[0].TraceID),
						instana.FormatID(spans[0].SpanID),
					),
				},
			}...)
		}

		if headerFormat == "both" || headerFormat == "string" || headerFormat == "" /* -> default, currently both */ {
			expected = append(expected, []kafka.Header{
				{Key: tracing.FieldLS, Value: []byte("1")},
				{
					Key:   tracing.FieldT,
					Value: []byte("0000000000000000" + instana.FormatID(spans[0].TraceID)),
				},
				{
					Key:   tracing.FieldS,
					Value: []byte(instana.FormatID(spans[0].SpanID)),
				},
			}...)
		}

		for _, h := range pm.Headers {
			switch h.Key {
			case w3ctrace.TraceParentHeader:
				p, err := w3ctrace.ParseParent(string(h.Value))
				assert.Nil(t, err)
				assert.Equal(t, "0af7651916cd43dd8448eb211c80319c", p.TraceID)
			case w3ctrace.TraceStateHeader:
				assert.Equal(t, "vendor1=90210", string(h.Value))
			}
		}

		os.Unsetenv(tracing.KafkaHeaderEnvVarKey)
	}
}

func TestSpanContextFromConsumerMessage(t *testing.T) {
	for _, headerFormat := range headerFormats {
		os.Setenv(tracing.KafkaHeaderEnvVarKey, headerFormat)

		sensor := instana.NewSensorWithTracer(
			instana.NewTracerWithEverything(&instana.Options{}, instana.NewTestRecorder()),
		)

		var headers []kafka.Header

		if headerFormat == "both" || headerFormat == "binary" || headerFormat == "" /* -> default, currently both */ {
			headers = []kafka.Header{
				{
					Key: "x_instana_c",
					Value: []byte{
						// trace id
						0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
						0x00, 0x00, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x12,
						// span id
						0x00, 0x00, 0x00, 0x00, 0xde, 0xad, 0xbe, 0xef,
					},
				},
				{Key: "x_instana_l", Value: []byte{0x01}},
			}
		}

		if headerFormat == "both" || headerFormat == "string" || headerFormat == "" /* -> default, currently both */ {
			headers = []kafka.Header{
				{Key: "x_instana_t", Value: []byte("000000000000000100000000abcdef12")},
				{Key: "x_instana_s", Value: []byte("00000000deadbeef")},
				{Key: "x_instana_l_s", Value: []byte("1")},
			}
		}

		msg := &kafka.Message{
			Headers: headers,
		}

		spanContext, err := tracing.SpanContextFromConsumerMessage(msg, sensor)
		require.Equal(t, nil, err)
		assert.Equal(t, instana.SpanContext{
			TraceIDHi: 0x00000001,
			TraceID:   0xabcdef12,
			SpanID:    0xdeadbeef,
			Baggage:   make(map[string]string),
		}, spanContext)

		os.Unsetenv(tracing.KafkaHeaderEnvVarKey)
	}
}

func TestSpanContextFromConsumerMessage_NoContext(t *testing.T) {
	examples := []struct {
		Name         string
		Headers      []kafka.Header
		HeaderFormat string
	}{
		{
			Name: "no tracing headers, header is binary",
			Headers: []kafka.Header{
				{Key: "key1", Value: []byte("value1")},
			},
			HeaderFormat: "binary",
		},
		{
			Name: "malformed tracing headers, header is binary",
			Headers: []kafka.Header{
				{Key: "x_instana_c", Value: []byte("malformed")},
				{Key: "x_instana_l", Value: []byte{0x00}},
			},
			HeaderFormat: "binary",
		},
		{
			Name: "incomplete trace headers, header is binary",
			Headers: []kafka.Header{
				{
					Key: "x_instana_c",
					Value: []byte{
						// trace id
						0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
						0x00, 0x00, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x12,
						// empty span id
						0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
					},
				},
				{Key: "x_instana_l", Value: []byte{0x01}},
			},
			HeaderFormat: "binary",
		},
		{
			Name: "no tracing headers, header is string",
			Headers: []kafka.Header{
				{Key: "key1", Value: []byte("value1")},
			},
			HeaderFormat: "string",
		},
		{
			Name: "malformed tracing headers, header is string",
			Headers: []kafka.Header{
				{Key: "x_instana_t", Value: []byte("malformed")},
				{Key: "x_instana_s", Value: []byte("malformed")},
				{Key: "x_instana_l_s", Value: []byte("0")},
			},
			HeaderFormat: "string",
		},
		{
			Name: "incomplete trace headers, header is string",
			Headers: []kafka.Header{
				{Key: "x_instana_t", Value: []byte("000000000000000100000000abcdef12")},
				{Key: "x_instana_s", Value: []byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}},
				{Key: "x_instana_l_s", Value: []byte("1")},
			},
			HeaderFormat: "string",
		},
		{
			Name: "malformed tracing headers, header is both",
			Headers: []kafka.Header{
				{Key: "x_instana_t", Value: []byte("malformed")},
				{Key: "x_instana_s", Value: []byte("malformed")},
				{Key: "x_instana_l_s", Value: []byte("0")},
				{Key: "x_instana_c", Value: []byte("malformed")},
				{Key: "x_instana_l", Value: []byte{0x00}},
			},
			HeaderFormat: "both",
		},
		{
			Name: "incomplete trace headers, header is both",
			Headers: []kafka.Header{
				{Key: "x_instana_t", Value: []byte("000000000000000100000000abcdef12")},
				{Key: "x_instana_s", Value: []byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}},
				{Key: "x_instana_l_s", Value: []byte("1")},
				{
					Key: "x_instana_c",
					Value: []byte{
						// trace id
						0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
						0x00, 0x00, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x12,
						// empty span id
						0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
					},
				},
				{Key: "x_instana_l", Value: []byte{0x01}},
			},
			HeaderFormat: "both",
		},
	}

	for _, example := range examples {
		t.Run(example.Name, func(t *testing.T) {
			os.Setenv(tracing.KafkaHeaderEnvVarKey, example.HeaderFormat)
			sensor := instana.NewSensorWithTracer(
				instana.NewTracerWithEverything(&instana.Options{}, instana.NewTestRecorder()),
			)

			msg := &kafka.Message{Headers: example.Headers}

			_, err := tracing.SpanContextFromConsumerMessage(msg, sensor)
			assert.NotEqual(t, nil, err)

			os.Unsetenv(tracing.KafkaHeaderEnvVarKey)
		})
	}
}

func TestSpanContextFromConsumerMessage_W3c(t *testing.T) {
	sensor := instana.NewSensorWithTracer(
		instana.NewTracerWithEverything(&instana.Options{}, instana.NewTestRecorder()),
	)

	msg := &kafka.Message{
		Headers: []kafka.Header{
			{Key: w3ctrace.TraceParentHeader, Value: []byte("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")},
			{Key: w3ctrace.TraceStateHeader, Value: []byte("vendor1=90210")},
		},
	}

	spanContext, err := tracing.SpanContextFromConsumerMessage(msg, sensor)
	require.Equal(t, nil, err)
	assert.Equal(t, instana.SpanContext{
		TraceIDHi: 790211418057950173,
		TraceID:   -8914616934935285348,
		SpanID:    -5211391058958601423,
		W3CContext: w3ctrace.Context{
			RawParent: "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
			RawState:  "vendor1=90210",
		},
		Baggage: make(map[string]string),
	}, spanContext)
}
