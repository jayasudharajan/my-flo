// +build unit

package main

import (
	"github.com/stretchr/testify/assert"
	"os"
	"testing"
)

func TestGetTopics(t *testing.T) {
	assert := assert.New(t)
	expectedTopics := []string{defaultConnectivityTopic, defaultDevicePropertiesTopic}

	t.Run("unit=GetTopicsPositiveTest", func(t *testing.T) {
		topics := getTopics()
		assert.Equal(len(expectedTopics), len(topics))
	})
}

func TestGetEnv(t *testing.T) {
	assert := assert.New(t)
	fallback := "leak"

	t.Run("unit=GetEnvFallbackTest", func(t *testing.T) {
		result := getEnv("DOESNT_EXIST", fallback)
		assert.Equal(fallback, result)
	})
	t.Run("unit=GetEnvPositiveTest", func(t *testing.T) {
		expected := "micro leak"
		testEnvVarKey := "TEST_GET_ENV"
		os.Setenv(testEnvVarKey, expected)
		result := getEnv(testEnvVarKey, fallback)
		assert.Equal(expected, result)
	})
}