package main

import (
	"os"
	"strconv"
)

const envVarRedisConnectionString = "REDIS_CN"
const envVarPgReadConnectionString = "PG_READ_CN"
const envVarPgWriteConnectionString = "PG_WRITE_CN"
const envVarArchiveIncidentOlderThanDays = "OLDER_THAN_DAYS"
const envVarAwsRegion = "AWS_REGION"
const envVarS3Bucket = "S3_BUCKET"
const envVarS3KeyQuery = "S3_KEY_QUERY"
const envVarIcdLogTable = "ICD_LOG_TABLE"

const defaultOlderThanDays = 31
const defaultAwsRegion = "us-west-2"

func main() {
	logInfo("main: incident archiver started")

	archiverConfig := buildArchiverConfig()

	logInfo("main: connecting to redis")
	redis := initRedis()
	logInfo("main: succesfully connected to redis")
	defer func() {
		logInfo("main: closing connection to redis")
		redis.Close()
	}()

	logInfo("main: connecting to main pg")
	pgWriteDb := initPgWriteSql()
	logInfo("main: succesfully connected to main pg")
	defer func() {
		logInfo("main: closing connection to main pg")
		pgWriteDb.Close()
	}()

	logInfo("main: connecting to read replica pg")
	pgReadDb := initPgReadSql()
	logInfo("main: succesfully connected to read replica pg")
	defer func() {
		logInfo("main: closing connection to read replica pg")
		pgReadDb.Close()
	}()

	logInfo("main: creating S3 session")
	s3 := initS3()
	logInfo("main: successfully created S3 session")

	logInfo("main: creating DynamoDb session")
	dynamoDb := initDynamoDb()
	logInfo("main: successfully created DynamoDb session")

	archiver, err := NewIncidentArchiver(archiverConfig, redis, pgReadDb, pgWriteDb, s3, dynamoDb)
	if err != nil {
		logError("main: error creating incident archiver - %v", err)
		os.Exit(1)
	}

	logInfo("main: archiving incidents")
	archiver.Start()
	logInfo("main: finished archiving incidents")
}

func buildArchiverConfig() *IncidentArchiverConfig {
	olderThanDays, err := strconv.Atoi(getEnvOrDefault(envVarArchiveIncidentOlderThanDays, strconv.Itoa(defaultOlderThanDays)))
	if err != nil {
		olderThanDays = defaultOlderThanDays
	}
	return &IncidentArchiverConfig{
		olderThanInDays: olderThanDays,
	}
}

func initRedis() *RedisConnection {
	redis, err := CreateRedisConnection(getEnvOrExit(envVarRedisConnectionString))
	if err != nil {
		logError("main: error connecting to redis - %v", err)
		os.Exit(2)
	}
	return redis
}

func initPgReadSql() *PgSqlDb {
	pgSql, err := OpenPgSqlDb(getEnvOrExit(envVarPgReadConnectionString))
	if err != nil {
		logError("main: error connecting to pg - %v", err)
		os.Exit(3)
	}
	return pgSql
}

func initPgWriteSql() *PgSqlDb {
	pgSql, err := OpenPgSqlDb(getEnvOrExit(envVarPgWriteConnectionString))
	if err != nil {
		logError("main: error connecting to pg - %v", err)
		os.Exit(3)
	}
	return pgSql
}

func initS3() *S3Handler {
	s3, err := CreateS3Session(getEnvOrDefault(envVarAwsRegion, defaultAwsRegion), getEnvOrExit(envVarS3Bucket))
	if err != nil {
		logError("main: error creating s3 session - %v", err)
		os.Exit(4)
	}
	return s3
}

func initDynamoDb() *DynamoDbHandler {
	dynamoDb, err := CreateDynamoDbSession(getEnvOrDefault(envVarAwsRegion, defaultAwsRegion), getEnvOrExit(envVarIcdLogTable))
	if err != nil {
		logError("main: error creating dynamoDb session - %v", err)
		os.Exit(4)
	}
	return dynamoDb
}
