package models

type TaskReq struct {
	MacAddress string `json:"macAddress"`
}

type TaskResponse struct {
	Id string `json:"id"`
}
