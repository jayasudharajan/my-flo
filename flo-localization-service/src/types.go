package main

import "time"

type Type struct {
	Type        string    `json:"type" mutable:"false" example:"sms"`
	Description string    `json:"description" mutable:"true" example:"text message"`
	Created     time.Time `json:"created" mutable:"false" example:"2019-05-23T04:13:14Z"`
	Updated     time.Time `json:"updated" mutable:"true" example:"2019-06-22T04:13:14Z"`
}

type TypeItems struct {
	Items []Type `json:"items"`
}

// Types is the struct to be used for multiple types response
type Types struct {
	Meta Meta `json:"meta"`
	TypeItems
}

type Tag struct {
	Id          string    `json:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6800"`
	AssetId     string    `json:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6869"`
	Name        string    `json:"name" example:"wordy"`
	Description string    `json:"name" example:"the asset is wordy"`
	Created     time.Time `json:"created_time"`
	Updated     time.Time `json:"updated_time"`
}

type LocalizedBase struct {
	Name   string `json:"name" example:"low_pressure_alert"`
	Type   string `json:"type" example:"sms"`
	Locale string `json:"locale" example:"ru-blr"`
}

type Localized struct {
	LocalizedBase
	Id             string `json:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6869"`
	LocalizedValue string `json:"localizedValue" example:"FLO has detected water low pressure, recommend to inspect water lines"`
	Ttl            int    `json:"ttl" example:"60"`
}

type LocalizedItems struct {
	Meta   LocalizedMeta `json:"meta"`
	Items  []interface{} `json:"items"`
	Errors []interface{} `json:"errors"`
}

type LocalizedRequest struct {
	LocalizedBase
	Args map[string]interface{} `json:"args"`
}

type LocalizedMeta struct {
	ErrorsCount int `json:"errorsCount"`
	ItemsCount  int `json:"itemsCount"`
	Total       int `json:"total"`
}

type LocalizedRequestItems struct {
	Items []LocalizedRequest `json:"items"`
}

type Locale struct {
	Id       string    `json:"id" mutable:"false" example:"ru_blr"`
	Fallback string    `json:"fallback" mutable:"true" example:"ru_ru"`
	Released bool      `json:"released" mutable:"true" example:"true"`
	Created  time.Time `json:"created" mutable:"false" example:"2019-05-23T04:13:14Z"`
	Updated  time.Time `json:"updated" mutable:"true" example:"2019-06-22T04:13:14Z"`
}

// Locales is the struct to be used for multiple locales response
type Locales struct {
	Meta  Meta     `json:"meta"`
	Items []Locale `json:"items"`
}

type ResponseOnCreatingNewLocale struct {
	Id string `json:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6969"`
}

// Ping is the ping response struct
type Ping struct {
	Status      int    `json:"status" example:"flo-localization-service"`
	Service     string `json:"service_name" example:"flo-localization-service"`
	CommitName  string `json:"commit_name" example:"Merge_branch_'ag_todos'_into_'dev'_cleanup_and_todo_See_merge_request_flotechnologies/flo-localization-service!49"`
	CommitSHA   string `json:"commit_sha" example:"b32ecf837b64055626a7403c15c8fb8195f4197a"`
	BuildDate   string `json:"build_date" example:"2019-05-03T18:44:37Z"`
	Environment string `json:"env" example:"dev"`
	Timestamp   string `json:"timestamp" example:"flo-localization-service"`
}

type ErrorResponse struct {
	StatusCode int    `json:"status"`
	Message    string `json:"message"`
}

type Asset struct {
	Id       string    `json:"id" mutable:"false" db:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6869"`
	Name     string    `json:"name" mutable:"true" db:"name" example:"low_pressure_alert"`
	Type     string    `json:"type" mutable:"true" db:"type" example:"sms"`
	Locale   string    `json:"locale" mutable:"true" db:"locale" example:"ru-blr"`
	Value    string    `json:"value" mutable:"true" db:"value" example:"FLO has detected water low pressure, recommend to inspect water lines"`
	Released bool      `json:"released" mutable:"true" db:"released" example:"true"`
	Tags     []string  `json:"tags" mutable:"true" db:"tags" example:"[wordy, to_revise, latest_release]"`
	Created  time.Time `json:"create" mutable:"false" db:"created" example:"2019-05-30T17:50:22.127785Z"`
	Updated  time.Time `json:"updated" mutable:"true" db:"updated" example:"2019-05]6-30T17:50:22.127785Z"`
}

type ResponseOnCreatingNewAsset struct {
	Id string `json:"id" example:"bd3a7efc-680a-40f8-bb52-bb754f9b6869"`
}

type AssetTagsMappings struct {
	JsonToDb map[string]string
	DbToJson map[string]string
}

// Meta is the meta data requests pagination
type Meta struct {
	Total  int `json:"total" example:"1"`
	Offset int `json:"offset" example:"0"`
	Limit  int `json:"limit" example:"10"`
}

// Assets is the struct to be used for multiple assets response
type Assets struct {
	Meta  Meta    `json:"meta"`
	Items []Asset `json:"items"`
}

type Filters struct {
	Name   string
	Locale string
	Type   string
	Offset int
	Limit  int
}
