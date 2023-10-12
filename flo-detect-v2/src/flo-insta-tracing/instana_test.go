package tracing_test

import (
	"testing"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	instana "github.com/instana/go-sensor"
	"github.com/instana/go-sensor/w3ctrace"
	"github.com/stretchr/testify/assert"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

func TestKafkaRoundTrip_W3c(t *testing.T) {
	// with only w3c header
	topic := "topic1"
	msg1 := &kafka.Message{
		TopicPartition: kafka.TopicPartition{
			Topic: &topic,
		},
		Key:   []byte("key1"),
		Value: []byte("value1"),
		Headers: []kafka.Header{
			{Key: "headerKey1", Value: []byte("headerValue1")},
			{Key: w3ctrace.TraceParentHeader, Value: []byte("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")},
			{Key: w3ctrace.TraceStateHeader, Value: []byte("vendor1=90210")},
		},
	}

	BaseTestKafkaRoundTrip(t, msg1)
}

func TestKafkaRoundTrip_insta(t *testing.T) {
	topic := "topic1"
	msg := &kafka.Message{
		TopicPartition: kafka.TopicPartition{
			Topic: &topic,
		},
		Key:   []byte("key1"),
		Value: []byte("value1"),
		Headers: []kafka.Header{
			{Key: "headerKey1", Value: []byte("headerValue1")},
			{Key: tracing.FieldT, Value: []byte("0af7651916cd43dd8448eb211c80319c")},
			{Key: tracing.FieldS, Value: []byte("b7ad6b7169203331")},
			{Key: tracing.FieldLS, Value: []byte("1")},
		},
	}

	BaseTestKafkaRoundTrip(t, msg)
}

func BaseTestKafkaRoundTrip(t *testing.T, msg *kafka.Message) {
	tracing.InitInstana("insta-kafka-demo")
	traceparent := "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"
	traceId := "0af7651916cd43dd8448eb211c80319c"
	traceHi, traceLo, err := instana.ParseLongID(traceId)
	assert.Nil(t, err)

	//
	// consume incoming message with tracecontext

	ctx, sp := tracing.InstaKafkaCtxExtractWithSpan(msg, "broker1,broker2")
	defer sp.Finish()

	// traceHi/Lo should match
	isc, ok := sp.Context().(instana.SpanContext)
	assert.True(t, ok)
	assert.Equal(t, traceHi, isc.TraceIDHi)
	assert.Equal(t, traceLo, isc.TraceID)
	// headers should match
	for _, h := range msg.Headers {
		switch h.Key {
		case w3ctrace.TraceParentHeader:
			assert.Equal(t, traceparent, string(h.Value))
		}
	}

	//
	// produce with ctx
	topic2 := "topic2"
	msg2 := &kafka.Message{
		TopicPartition: kafka.TopicPartition{
			Topic: &topic2,
		},
		Key:   []byte("key2"),
		Value: []byte("value2"),
		Headers: []kafka.Header{
			{Key: "headerKey2", Value: []byte("headerValue2")},
		},
	}

	msg2_inserted := tracing.InstaKafkaCtxInsert(ctx, msg2)

	// compare with original span
	// traceId should be same
	p, err := w3ctrace.ParseParent(isc.W3CContext.RawParent)
	assert.Nil(t, err)
	assert.Equal(t, traceId, p.TraceID)
	// headers should match
	found := false
	for _, h := range msg2_inserted.Headers {
		switch h.Key {
		case w3ctrace.TraceParentHeader:
			found = true
			ph, err := w3ctrace.ParseParent(string(h.Value))
			assert.Nil(t, err)
			assert.Equal(t, traceId, ph.TraceID)
		case tracing.FieldT:
			assert.Equal(t, traceId, string(h.Value))
		}
	}
	assert.True(t, found)

	//
	// consume again
	_, sp3 := tracing.InstaKafkaCtxExtractWithSpan(msg2_inserted, "brokers")
	defer sp3.Finish()

	isc3, ok3 := sp3.Context().(instana.SpanContext)
	assert.True(t, ok3)
	p3, err3 := w3ctrace.ParseParent(isc3.W3CContext.RawParent)
	assert.Nil(t, err3)
	assert.Equal(t, traceId, p3.TraceID)

}
