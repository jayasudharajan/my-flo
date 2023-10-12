package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCanInclude(t *testing.T) {
	var dd *deviceDiscovery
	check := func(dt string, ok bool) {
		assert.Equal(t, ok, dd.isDeviceDiscoverable(&Device{DeviceType: dt}), "canInclude check of %v !%v", dt, ok)
	}
	check("flo_device_v2", true)
	check("flo_device_v1", false)
	check("flo_device_v3.9", true)
	check("puck_oem", false)
	check("blah", false)
}
