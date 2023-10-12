// +build unit

package main

import (
	"encoding/json"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestComputeHash(t *testing.T) {
	assert := assert.New(t)

	oLog := &KafkaOnboardingLogEvent{
		DeviceId: "a810872402b3",
		Id:       "c5bece3a-ac5d-11eb-8079-a810872402b9",
		Event:    LogEvent{Name: "installed"},
	}

	hash, ttls, err := computeHash(oLog.Id, oLog.DeviceId)
	assert.NotEmpty(hash)
	assert.GreaterOrEqual(ttls, 1800)
	assert.NoError(err)
}

func TestProcessOnboardingEventsTopic(t *testing.T) {
	assert := assert.New(t)

	oLog := KafkaOnboardingLogEvent{
		DeviceId: "a810872402b3",
		Id:       "c5bece3a-ac5d-11eb-8079-a810872402b9",
		Event:    LogEvent{Name: "installed"},
	}

	oLogBytes, _ := json.Marshal(oLog)

	t.Run("unit=ProcessOnboardingEventsTopicWithNoErrorTest", func(t *testing.T) {
		err := ProcessOnboardingEventsTopic(oLogBytes)
		assert.NoError(err)
	})

	t.Run("unit=ProcessOnboardingEventsDuplicateTopicWithNoErrorTest", func(t *testing.T) {
		err := ProcessOnboardingEventsTopic(oLogBytes)
		assert.NoError(err)
	})
}
