package tracing

import (
	"github.com/confluentinc/confluent-kafka-go/kafka"
)

// var _ propagation.TextMapCarrier = (*OtelMessageCarrier)(nil)

// OtelMessageCarrier injects and extracts traces from a kafka.Message.
type OtelMessageCarrier struct {
	msg *kafka.Message
}

// NewOtelMessageCarrier creates a new OtelMessageCarrier.
func NewOtelMessageCarrier(msg *kafka.Message) OtelMessageCarrier {
	return OtelMessageCarrier{msg: msg}
}

// Get retrieves a single value for a given key.
func (c OtelMessageCarrier) Get(key string) string {
	for _, h := range c.msg.Headers {
		if string(h.Key) == key {
			return string(h.Value)
		}
	}
	return ""
}

// Set sets a header.
func (c OtelMessageCarrier) Set(key, val string) {
	// Ensure uniqueness of keys
	for i := 0; i < len(c.msg.Headers); i++ {
		if string(c.msg.Headers[i].Key) == key {
			c.msg.Headers = append(c.msg.Headers[:i], c.msg.Headers[i+1:]...)
			i--
		}
	}
	c.msg.Headers = append(c.msg.Headers, kafka.Header{
		Key:   key,
		Value: []byte(val),
	})
}

// Keys returns a slice of all key identifiers in the carrier.
func (c OtelMessageCarrier) Keys() []string {
	out := make([]string, len(c.msg.Headers))
	for i, h := range c.msg.Headers {
		out[i] = string(h.Key)
	}
	return out
}
