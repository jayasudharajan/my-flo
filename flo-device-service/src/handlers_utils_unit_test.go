// +build unit

package main

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestIsValidDeviceID(t *testing.T) {
	assert := assert.New(t)
	setup()
	knownGoodDeviceID := "c8df845a335e"
	diffLengthDeviceID := "c8df845a335eaaa"
	unexpectedCharDeviceID := "c8wf845a335"
	t.Run("unit=IsValidDeviceIDPositiveTest", func(t *testing.T) {
		result := isValidDeviceMac(knownGoodDeviceID)
		assert.True(result, "they should be true")
	})
	t.Run("unit=IsValidDeviceIDNegativeWithDiffLengthTest", func(t *testing.T) {
		result := isValidDeviceMac(diffLengthDeviceID)
		assert.False(result, "they should be false")
	})
	t.Run("unit=IsValidDeviceIDNegativeWithUnexpectedCharTest", func(t *testing.T) {
		result := isValidDeviceMac(unexpectedCharDeviceID)
		assert.False(result, "they should be false")
	})
}
