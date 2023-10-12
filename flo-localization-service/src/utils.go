package main

import (
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"

	"github.com/google/uuid"
)

const localeSeparatorStandard = "-"
const localeSeparatorAlternative = "_"

// MapJsonToDbAndDbToJson returns tags mappings, first Json to Db map, second Db to Json
func MapJsonToDbAndDbToJson(d interface{}) (map[string]string, map[string]string) {
	var jsonToDb = make(map[string]string)
	var dbToJson = make(map[string]string)
	v := reflect.ValueOf(d)
	numOfFields := v.Type().NumField()
	for i := 0; i < numOfFields; i++ {
		db := v.Type().Field(i).Tag.Get("db")
		json := v.Type().Field(i).Tag.Get("json")
		jsonToDb[json] = db
		dbToJson[db] = json
	}
	return jsonToDb, dbToJson
}

// GetMutableStructJsonFields returns the map of mutable json tags
func GetMutableStructJsonFields(d interface{}) (map[string]bool, error) {
	var result = make(map[string]bool)
	v := reflect.ValueOf(d)
	numOfFields := v.Type().NumField()
	for i := 0; i < numOfFields; i++ {
		mutableFlagStr := v.Type().Field(i).Tag.Get("mutable")
		mutableFlag, err := strconv.ParseBool(mutableFlagStr)
		if err != nil {
			return nil, err
		}
		jsonTagValue := v.Type().Field(i).Tag.Get("json")
		if mutableFlag {
			result[jsonTagValue] = true
		}
	}
	return result, nil
}

// GenerateUuid generates UUID string
func GenerateUuid() (string, error) {
	return uuid.New().String(), nil
	// vs.
	//return generateUuid()
}

// NormalizeLocale translate the locale string to ll_cc format
func NormalizeLocale(locale string) (string, error) {
	var splitLocale []string
	if strings.Contains(locale, localeSeparatorStandard) {
		splitLocale = strings.Split(locale, localeSeparatorStandard)
	} else if strings.Contains(locale, localeSeparatorAlternative) {
		splitLocale = strings.Split(locale, localeSeparatorAlternative)
	} else {
		return EmptyString, errors.New("invalid locale format")
	}
	lang := strings.ToLower(splitLocale[0])
	region := strings.ToLower(splitLocale[1])
	return fmt.Sprintf("%s%s%s", lang, localeSeparatorStandard, region), nil
}
