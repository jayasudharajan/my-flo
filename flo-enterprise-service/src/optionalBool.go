package main

import (
	"encoding/json"
)

type OptionalBool struct {
	Value    bool
	HasValue bool // true if bool is not null
}

func (optionalBool OptionalBool) MarshalJSON() ([]byte, error) {
	if optionalBool.HasValue {
		return json.Marshal(optionalBool.Value)
	}
	return json.Marshal(false)
}

func (optionalBool *OptionalBool) UnmarshalJSON(b []byte) error {
	var parsedJsonValue bool
	err := json.Unmarshal(b, &parsedJsonValue)
	if err != nil {
		return err
	}
	optionalBool.Value = parsedJsonValue
	optionalBool.HasValue = true
	return nil
}
