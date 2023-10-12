// +build unit

package main

import (
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
)

// DeviceTest is the device properties struct
type DeviceTest struct {
	DeviceId    string `json:"deviceId"`
	IsConnected bool   `json:"isConnected"`
	FwVersion   string `json:"fwVersion"`
}

func TestGenerateUuid(t *testing.T) {
	assert := assert.New(t)
	uuid, err := GenerateUuid()
	t.Run("unit=GenerateUuidPositiveTest", func(t *testing.T) {
		assert.True(isValidUUID(uuid))
		assert.Nil(err)
	})
}

func TestFindRequestBodyEmptyFields(t *testing.T) {
	assert := assert.New(t)
	t.Run("unit=FindRequestBodyEmptyFieldsPositiveTest", func(t *testing.T) {
		enforcedFields := map[string]interface{}{"deviceId": true, "fwVersion": true}
		d := DeviceTest{
			DeviceId:    "",
			IsConnected: false,
			FwVersion:   "",
		}
		result := FindRequestBodyEmptyFields(d, enforcedFields)
		assert.Equal(len(enforcedFields), len(result))
	})
	t.Run("unit=FindRequestBodyEmptyFieldsTwoEmptyFieldsTest", func(t *testing.T) {
		enforcedFields := map[string]interface{}{"deviceId": true, "fwVersion": true, "isConnected": true}
		const expectedNumOfEmptyFields = 2
		d := DeviceTest{
			DeviceId:    "",
			IsConnected: false,
			FwVersion:   "",
		}
		result := FindRequestBodyEmptyFields(d, enforcedFields)
		assert.Equal(expectedNumOfEmptyFields, len(result))
	})
	t.Run("unit=FindRequestBodyEmptyFieldsNoEmptyFieldsTest", func(t *testing.T) {
		enforcedFields := map[string]interface{}{"deviceId": true, "fwVersion": true, "isConnected": true}
		const expectedNumOfEmptyFields = 0
		d := DeviceTest{
			DeviceId:    "myid",
			IsConnected: false,
			FwVersion:   "3.5.18",
		}
		result := FindRequestBodyEmptyFields(d, enforcedFields)
		assert.Equal(expectedNumOfEmptyFields, len(result))
	})
}

func isValidUUID(uuid string) bool {
	r := regexp.MustCompile("^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[8|9|a|b][a-f0-9]{3}-[a-f0-9]{12}$")
	return r.MatchString(uuid)
}
