// +build unit

package main

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDevicePresence(t *testing.T) {
	assert := assert.New(t)

	t.Run("unit=TestGetDevicePresenceKey", func(t *testing.T) {
		keys := getDevicePresenceKeys()
		println(strings.Join(keys, ","))
		assert.Equal(3, len(keys))

	})
}
