package Kafka

type VoiceMessage struct {
	Id          string `json:"id"`
	RequestInfo RequestData `json:"request_info"`
	Message     string `json:"message"`
}

type RequestData struct {
	Time     string `json:"time"`
	AppName  string `json:"app_name"`
	Category int64 `json:"category"`
	Version  int64 `json:"version"`
}

type DefaultCall struct {
	From              string   `json:"from"`
	To                string   `json:"to"`
	ScriptUrl         string   `json:"script_url"`
	StatusCallbackUrl string   `json:"status_callback_url"`
	CallMetaData      MetaData `json:"call_meta_data"`
}

type MetaData struct {
	DeviceId        string `json:"device_id"`
	IcdId           string `json:"icd_id"`
	UserId          string `json:"user_id"`
	AlarmId         int64 `json:"alarm_id"`
	SystemMode      int64 `json:"system_mode"`
	InternalAlarmId int64 `json:"internal_alarm_id"`
}
