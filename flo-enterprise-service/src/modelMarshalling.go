package main

import (
	"encoding/json"
	"reflect"
	"strings"
)

/*
 * Custom EntityActivityDevice serializer since LTEPaired is only present when
 * the DeviceUpdated event pertains to an LTE link-unlink action. It is not
 * accurate to include lte_paired as false if the current state is linked
 * therefore the "OptionalBool" is excluded if "HasValue" is false.
 * It is not recursive. It only applies to top level OptionalBool properties.
 */
func (node EntityActivityDevice) MarshalJSON() ([]byte, error) {
	props := map[string]interface{}{}

	reflectedType := reflect.TypeOf(node)
	reflectedValue := reflect.ValueOf(node)

	for i := 0; i < reflectedType.NumField(); i++ {
		field := reflectedType.Field(i)
		fieldValue := reflectedValue.Field(i).Interface()

		jsonFieldName := field.Name
		annotation, ok := field.Tag.Lookup("json")
		tagSegments := strings.Split(annotation, ",")
		if ok && len(tagSegments) > 0 && len(tagSegments[0]) > 0 {
			jsonFieldName = tagSegments[0]
		} else {
			jsonFieldName = strings.ToLower(string(jsonFieldName[0])) + jsonFieldName[1:]
		}

		switch fieldValue.(type) {
		case OptionalBool:
			if fieldValue.(OptionalBool).HasValue {
				props[jsonFieldName] = fieldValue.(OptionalBool).Value
			}
		default:
			if !strings.Contains(annotation, "omitempty") || (strings.Contains(annotation, "omitempty") && !reflect.ValueOf(fieldValue).IsZero()) {
				props[jsonFieldName] = fieldValue
			}
		}
	}

	return json.Marshal(props)
}
