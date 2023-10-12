package main

type ErrorResponse struct {
	StatusCode int    `json:"status"`
	Message    string `json:"message"`
}

// Ping is the ping response struct
type Ping struct {
	Status      int                    `json:"status" example:"flo-firewriter"`
	Service     string                 `json:"serviceName" example:"flo-firewriter"`
	CommitName  string                 `json:"commitName" example:"cleanup_and_todo"`
	CommitSHA   string                 `json:"commitSha" example:"b32ecf837b64055626a7403c15c8fb8195f4197a"`
	BuildDate   string                 `json:"buildDate" example:"2019-05-03T18:44:37Z"`
	Environment string                 `json:"env" example:"dev"`
	Timestamp   string                 `json:"timestamp" example:"2019-05-03T18:44:37Z"`
	Stats       map[string]interface{} `json:"stats"`
}
