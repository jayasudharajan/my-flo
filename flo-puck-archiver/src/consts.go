package main

import (
	"strings"
	"time"
)

const (
	envVarAppName = "APPLICATION_NAME"
	envVarEnvName = "ENVIRONMENT"

	envVarAwsRegion = "AWS_REGION"

	envVarS3Bucket                = "FLO_ARCHIVE_S3_BUCKET"
	envVarPgConnectionString      = "FLO_ARCHIVE_PG_CN"
	envVarPgReadConnectionString  = "FLO_ARCHIVE_PG_READ_CN"
	envVarLocalDebug              = "FLO_LOCAL_DEBUG"
	envVarLogMinLevel             = "FLO_LOG_MIN_LEVEL"
	envVarArchiveRecordsOlderThan = "FLO_ARCHIVE_DAYS_TRESHOLD"
	envVarArchiveMaxLimit         = "FLO_ARCHIVE_PROC_LIMIT_DAYS"

	defaultAwsRegion               = "us-west-2"
	defaultLogPrefix               = "flo-puck-archiver"
	defaultArchiveRecordsOlderThan = 365
	defaultArchiveMaxLimit         = 3
)

const (
	ATTRIBUTE_PUCK_TLM_ARCHIVE_END = "telemetry_archive_end_date"
	// device ids to process rather that the whole population, in order to test, slow roll it or
	// workaround the fact that we dont have a date only index
	ATTRIBUTE_PUCK_TLM_ARCHIVE_HINT = "telemetry_archive_device_hint"
)

const (
	HASH_DATE_LAYOUT       = "0106"       // MMYY
	SHORT_DATE_LAYOUT      = "20060102"   // YYYYMMDD
	SHORT_DATE_PATH_LAYOUT = "2006/01/02" // YYYY/MM/DD
	STD_DATE_LAYOUT        = "2006-01-02T15:04:05"
	DUR_1_DAY              = time.Hour * 24
	ARCHIVE_STEP_UP_DUR    = DUR_1_DAY
)

func environmentConst() string {
	return strings.TrimSpace(getEnvOrDefault(envVarEnvName, getEnvOrDefault("ENV", "local")))
}
