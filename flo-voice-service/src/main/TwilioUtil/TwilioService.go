package TwilioUtil

import (
  "context"	
	"main/Structures/Kafka"
	"main/util"
	"errors"
	"encoding/json"
	"net/url"
)

func MakeCall(msg Kafka.VoiceMessage) {
	requestInfo, err2 := json.Marshal(msg.RequestInfo)
	if err2 != nil {
		loggy.Log.Println(loggy.Error(err2, "deserializing request info for msg id: "+msg.Id))
		return
	}
	category, err := GetRequestCategory(msg)
	if err != nil {
		loggy.Log.Println(loggy.Error(err, "Error happened getting category for msg id: "+string(requestInfo)))
		return
	}
	switch category {
	case 1:
		callInfo, err := GetCallInfoFromMessage(msg)
		if err != nil {
			loggy.Log.Println(loggy.Error(err, "Error happened deseriallizing call info for request info: "+string(requestInfo)))
			break
		}
		success, callError := MakeDefaultCall(callInfo)
		if callError != nil {
			loggy.Log.Println(loggy.Error(callError, "Error happened making  call  for request info: "+string(requestInfo)))
			break
		}
		if success {
			loggy.Log.Println(loggy.Info("Call successfully made for request info " + string(requestInfo)))
		} else {
			loggy.Log.Println(loggy.Warning("Call had an unknown error for request info " + string(requestInfo)))
		}
	default:
		loggy.Log.Println(loggy.Error(errors.New("Unknown Category"), " request info: "+string(requestInfo)))
	}
}

func MakeDefaultCall(callInfo Kafka.DefaultCall) (bool, error) {
	metaData, _ := json.Marshal(callInfo.CallMetaData)

	config, err := util.GetConfiguration()
	if err != nil {
		loggy.Log.Println(loggy.Error(err, "Error retrieving configuration for application"))
		return false, err
	}
	client, clientErr := CreateClient(config.TwilioSID, config.TwilioAuthToken)
	if clientErr != nil {
		loggy.Log.Println(loggy.Error(clientErr, "Error creating Twilio client"))
		return false, clientErr
	}
	scriptUrl, errorScriptUrl := url.Parse(callInfo.ScriptUrl)
	if errorScriptUrl != nil {
		loggy.Log.Println(loggy.Error(errorScriptUrl, "Error parsing script URL"))
		return false, errorScriptUrl
	}
	statusCallbackUrl, err := url.Parse(callInfo.StatusCallbackUrl)
	if err != nil {
		loggy.Log.Println(loggy.Error(err, "Error parsing status callback URL"))
		return false, err
	}

	var callerNumber string = callInfo.From
	if callerNumber == "" {
		callerNumber = config.TwilioNumber
	}

	data := url.Values{}
	data.Set("From", callerNumber)
	data.Set("To", callInfo.To)
	data.Set("Url", scriptUrl.String())
	data.Set("StatusCallback", statusCallbackUrl.String())
	data.Set("StatusCallbackMethod", "POST")
	/* Set timeout in seconds to consider this call as "no-answer" 
	   (otherwise, if the answering machine picks up, the status will be "completed")
	*/
	data.Set("Timeout", "25") 
	result, errorResult := client.Calls.Create(context.Background(), data)
	if errorResult != nil {
		loggy.Log.Println(loggy.Error(errorResult, "Error making call  script URL"))
		return false, errorResult
	}

	loggy.Log.Println(loggy.Info("call successfully made price" + result.Price + " duration: " + result.Duration.String() + " call metaData" + string(metaData)))
	
	return true, nil
}
func GetCallInfoFromMessage(m Kafka.VoiceMessage) (Kafka.DefaultCall, error) {
	var defaultCall Kafka.DefaultCall
	requestInfo, err2 := json.Marshal(m.RequestInfo)
	if err2 != nil {
		loggy.Log.Println(loggy.Error(err2, "deserializing request info for msg id: "+m.Id))
		return defaultCall, err2
	}
	if errorDeserializing := json.Unmarshal([]byte(m.Message), &defaultCall); errorDeserializing != nil {
		loggy.Log.Println(loggy.Error(errorDeserializing, "deserializing defaultCall from voice message  for request Info: "+string(requestInfo)))
		return defaultCall, errorDeserializing
	}
	return defaultCall, nil
}

func GetRequestCategory(m Kafka.VoiceMessage) (int64, error) {
	switch m.RequestInfo.Category {
	case 1:
		return 1, nil
	default:
		return 0, errors.New("Unknown  category ")
	}

}
