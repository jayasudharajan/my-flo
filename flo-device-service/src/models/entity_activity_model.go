package models

type EntityActivity struct {
	DeviceId       string                 `json:"id,omitempty"`
	Item           map[string]interface{} `json:"item,omitempty"`
	ActivityType   string                 `json:"type,omitempty"`
	ActivityAction string                 `json:"action,omitempty"`
}

type DeviceEntityActivityItem struct {
	MacAddress string                       `json:"macAddress,omitempty"`
	LTEPaired  *bool                        `json:"lte_paired,omitempty"`
	Location   DeviceEntityActivityLocation `json:"location,omitempty"`
}

type DeviceEntityActivityLocation struct {
	Id string `json:"id"`
}
