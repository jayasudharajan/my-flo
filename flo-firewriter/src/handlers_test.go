// +build unit

package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestIsValidDeviceID(t *testing.T) {
	assert := assert.New(t)
	setup()
	knownGoodDeviceID := "c8df845a335e"
	diffLengthDeviceID := "c8df845a335eaaa"
	unexpectedCharDeviceID := "c8wf845a335"
	t.Run("unit=IsValidDeviceIDPositiveTest", func(t *testing.T) {
		result := isValidDeviceId(knownGoodDeviceID)
		assert.True(result, "they should be true")
	})
	t.Run("unit=IsValidDeviceIDNegativeWithDiffLengthTest", func(t *testing.T) {
		result := isValidDeviceId(diffLengthDeviceID)
		assert.False(result, "they should be false")
	})
	t.Run("unit=IsValidDeviceIDNegativeWithUnexpectedCharTest", func(t *testing.T) {
		result := isValidDeviceId(unexpectedCharDeviceID)
		assert.False(result, "they should be false")
	})
}
