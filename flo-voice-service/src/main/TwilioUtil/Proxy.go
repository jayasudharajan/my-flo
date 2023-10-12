package TwilioUtil

import (
	"github.com/kevinburke/twilio-go"
	"main/util"
	logging "main/loggy"
)

var loggy = logging.Init()

func CreateClient(sid string, token string) (*twilio.Client, error) {

	var config, err = util.GetConfiguration()
	if err != nil {
		loggy.Log.Println(loggy.Error(err, "there was a problem  getting the application configuration"))
		return nil, err
	}
	var tSID = sid
	if sid == "" {
		tSID = config.TwilioSID
	}
	var twilioToken = token
	if token == "" {
		twilioToken = config.TwilioAuthToken
	}

	client := twilio.NewClient(tSID, twilioToken, nil)
	return client, nil

}


