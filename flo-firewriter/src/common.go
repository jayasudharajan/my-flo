package main

import (
	"os"
	"reflect"
	"regexp"

	"github.com/google/uuid"
)

const APP_NAME = "flo-firewriter"

// APIVersion API version
const APIVersion = "v1"

// EmptyString is the empty string value
const EmptyString = ""

// NoneValue is the string none value
const NoneValue = "none"

// CollectionKey is the collection key
const CollectionKey = "collection"

// DeviceIdRegex is the device id regex
var DeviceIdRegex *regexp.Regexp

// CompileDeviceServiceRegexes compiles device service regexes
func CompileDeviceServiceRegexes() {
	var err error
	DeviceIdRegex, err = regexp.Compile("^([a-fA-F0-9]{12})$")
	if err != nil {
		logError("failed to compile deviceID regex, err: %v", err)
	}
}

// FindRequestBodyEmptyFields finds request body empty fields among the enforced ones
func FindRequestBodyEmptyFields(d interface{}, enforcedJSONFields map[string]interface{}) []string {
	v := reflect.ValueOf(d)
	var emptyJSONFields []string
	for i := 0; i < v.Type().NumField(); i++ {
		fieldName := v.Type().Field(i).Name
		tag := v.Type().Field(i).Tag.Get("json")
		if _, ok := enforcedJSONFields[tag]; ok {
			val := reflect.Indirect(v).FieldByName(fieldName)
			// what if it's not string?
			if val.String() == EmptyString {
				emptyJSONFields = append(emptyJSONFields, tag)
			}
		}
	}
	return emptyJSONFields
}

// GenerateUuid generates UUID string
func GenerateUuid() (string, error) {
	return uuid.New().String(), nil
}

// getEnvOrExit Retrieve env var - if empty/missing the process will exit
func getEnvOrExit(envVarName string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		logError("Missing environment variable: %v", envVarName)
		os.Exit(-10)
		return ""
	}
	return val
}

// getEnvOrDefault Retrieve env var - if empty/missing, will return defaultValue
func getEnvOrDefault(envVarName string, defaultValue string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		return defaultValue
	}
	return val
}
