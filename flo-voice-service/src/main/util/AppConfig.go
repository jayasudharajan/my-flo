package util

import (
	"os"
	"strconv"
	"strings"
	"errors"
)

const fromEnvironment bool = true

var configurationStrings = map[string]string{
	"KAFKA_HOST":        "foo",
	"KAFKA_GROUP_ID":    "foo-5000",
	"KAFKA_VOICE_TOPIC": "foo",
	"TWILIO_SID":        "foo",
	"TWILIO_AUTH_TOKEN": "foo",
	"TWILIO_NUMBER":     "1800foo",
}
var configurationInts = map[string]int64{
	"SERVICE_COMMAND": run,
}

//service Commands enums
const (
	run  = 1
	stop = 2
)

type Configuration struct {
	KafkaHost       []string
	KafkaGroupId    string
	KafkaVoiceTopic string
	ServiceCommand  int64
	TwilioSID       string
	TwilioAuthToken string
	TwilioNumber    string
}

func GetConfiguration() (Configuration, error) {
	var config Configuration
	var err error
	kafkaHost, err := getSlice("KAFKA_HOST")
	if err != nil {
		return config, err
	}
	kafkaGroupId, err := getString("KAFKA_GROUP_ID")
	if err != nil {
		return config, err
	}
	kafkaDeviceVersionTopic, err := getString("KAFKA_VOICE_TOPIC")
	if err != nil {
		return config, err
	}
	serviceCommand, err := getInt("SERVICE_COMMAND")
	if err != nil {
		return config, err
	}
	twilioSID, err := getString("TWILIO_SID")
	if err != nil {
		return config, err
	}
	twilioAuthToken, err := getString("TWILIO_AUTH_TOKEN")
	if err != nil {
		return config, err
	}
	twilioNumber, err := getString("TWILIO_NUMBER")
	if err != nil {
		return config, err
	}

	config = Configuration{
		KafkaHost:       kafkaHost,
		KafkaGroupId:    kafkaGroupId,
		KafkaVoiceTopic: kafkaDeviceVersionTopic,
		ServiceCommand:  serviceCommand,
		TwilioSID:       twilioSID,
		TwilioAuthToken: twilioAuthToken,
		TwilioNumber:    twilioNumber,
	}
	return config, nil
}

func getString(envVar string) (string, error) {
	switch {
	case fromEnvironment:
		var v string = os.Getenv(envVar)
		if v == "" {
			return v, errors.New("value for env var: " + envVar + " not found")
		}
		return v, nil
	case !fromEnvironment:
		return configurationStrings[envVar], nil
	}
	return "", errors.New("value could not be recovered from env var")
}

func getInt(envVar string) (int64, error) {
	switch {
	case fromEnvironment:
		var v string = os.Getenv(envVar)
		if v == "" {
			return 0, errors.New("value for env var: " + envVar + " not found")
		}
		i, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			return 0, errors.New("value for env var: " + envVar + " could not be converted to Int error")
		}
		return i, nil

	case !fromEnvironment:
		return configurationInts[envVar], nil
	}
	return 0, errors.New("value was not found in environment or config map!!!")
}
func getSlice(envVar string) ([]string, error) {

	switch {
	case fromEnvironment:
		var v string = os.Getenv(envVar)
		if v == "" {
			return nil, errors.New("value for env var: " + envVar + " not found")
		}
		s := strings.Split(v, ",")
		if s == nil {

			return nil, errors.New("value for env var: " + envVar + " could not be converted to slice error")
		}
		return s, nil

	case !fromEnvironment:
		s := strings.Split(configurationStrings[envVar], ",")
		if s == nil {

			return nil, errors.New("value for env var: " + envVar + " could not be converted to slice error from config map ")
		}
		return s, nil
	}
	return nil, errors.New("value was not found in environment or config map!!!")
}
