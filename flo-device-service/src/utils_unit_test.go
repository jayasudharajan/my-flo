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

func Test_Version_Check_No_Min_Under_Max(t *testing.T) {
	v_under, err_under := versionCheck("4.0.0", "", "6.0.0-test1")
	assert.Nil(t, err_under)
	assert.True(t, v_under)
}

func Test_Version_Check_No_Min_Same_Max(t *testing.T) {
	v_same, err_same := versionCheck("6.0.0", "", "6.0.0-test2")
	assert.Nil(t, err_same)
	assert.False(t, v_same)
}

func Test_Version_Check_No_Max_Over_Min(t *testing.T) {
	v_over, err_over := versionCheck("6.1.0-test1", "6.0.0", "")
	assert.Nil(t, err_over)
	assert.True(t, v_over)
}

func Test_Version_Check_No_Max_Under_Min(t *testing.T) {
	v_under, err_under := versionCheck("5.0.0-test1", "6.0.0", "")
	assert.Nil(t, err_under)
	assert.False(t, v_under)
}
func Test_Version_Check_Max_Min_Between(t *testing.T) {
	v, err := versionCheck("7.0.0-test1", "6.0.0", "10.1.2-test4")
	assert.Nil(t, err)
	assert.True(t, v)
}

func Test_Version_Check_Max_Min_Missed(t *testing.T) {
	v, err := versionCheck("3.3.0-test1", "6.0.0", "10.1.2-test4")
	assert.Nil(t, err)
	assert.False(t, v)
}
