package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

const commitSHAKey = "COMMIT_SHA"
const commitNameKey = "COMMIT_NAME"
const buildDateKey = "BUILD_DATE"

const serviceNameKey = "SERVICE_NAME"
const envKey = "ENVIRONMENT"

const webServerPortKey = "WEB_SERVER_PORT"

const logsLevelKey = "LOGS_LEVEL"

const googleCloudProjectIDKey = "GOOGLE_PROJECT_ID"
const googleAppCredsKey = "GCP_SERVICE_ACCOUNT_CREDENTIALS"

const kafkaBrokersKey = "KAFKA_BROKERS"
const kafkaGroupIdKey = "KAFKA_GROUP_ID"
const kafkaFirestoreWriterTopicKey = "KAFKA_FS_WRITER_TOPIC"
const kafkaConsumersNumKey = "KAFKA_CONSUMERS_NUM"
const kafkaConsumerTimeoutKey = "KAFKA_CONSUMER_TIMEOUT"
const kafkaAutoOffsetResetKey = "DS_KAFKA_AUTO_OFFSET_RESET"

const kafkaSecurityProtocolKey = "KAFKA_SECURITY_PROTOCOL"
const kafkaTlsCaLocationKey = "KAFKA_TLS_CA_LOCATION"
const kafkaTlsCertLocationKey = "KAFKA_TLS_CERT_LOCATION"
const kafkaTlsKeyLocationKey = "KAFKA_TLS_KEY_LOCATION"
const kafkaTlsKeyPasswordKey = "KAFKA_TLK_KEY_PASSWORD"

const knownFsCollections = "KNOWN_FS_COLLECTIONS"

// ******************** Defaults ********************

const DefaultEnv = "prod-local"
const DefaultServiceName = "flo-firewriter"
const defaultWebServerPort = "3000"

// default logs level is set to 2 -> INFO
const defaultLogsLevel = "1"

const defaultGoogleProjectID = "flotechnologies-1b111"

const defaultGoogleAppCreds = "creds/flo_ds_service_account_key.json"

const numOfInitParams = 3

//const defaultKafkaBrokerURLs = "kafka-cherry-broker-1.dev.flocloud.co:9092,kafka-cherry-broker-2.dev.flocloud.co:9092,kafka-cherry-broker-3.dev.flocloud.co:9092"
const defaultkafkaFirestoreWriterTopic = "firestore-write-v1"
const defaultKafkaConsumersNum = "1"
const defaultKafkaConsumerTimeout = "6000"
const defaultKafkaAutoOffsetReset = "latest"

const defaultKnownFsCollections = "devices,locations,users"

const stringToIntConversionErrMsg = "failed to convert %s string value to int"

// CommitSHA is the git commit sha
var CommitSHA string

// CommitName is the git commit name
var CommitName string

// BuildDate is the build date
var BuildDate string

// ServiceName is the service name
var ServiceName string

// Env is the environment the service is running in
var Env string

// WebServerPort is the web server port for device state service API, defaulted to 3000
var WebServerPort string

// LogsLevel is the logs level, e.g. 1 -> DEBUG
var LogsLevel int

// GoogleProjectID is the google project ID
var GoogleProjectID string

// GoogleAppCreds is the path to google application credentials file
var GoogleAppCreds string

// KafkaBrokerUrls is kafka broker URLs, csv formatted
var KafkaBrokerUrls string

// KafkaGroupId is kafka consumer group ID
var KafkaGroupId string

// KafkaFirestoreWriterTopic is the kafka Firestore writer topic
var KafkaFirestoreWriterTopic string

// KafkaConsumersNum is the number of kafka consumers
var KafkaConsumersNum int

// KafkaTopics are kafka topics kafka consumer is listening on
var KafkaTopics []string

// KafkaTimeout is kafka consumer timeout
var KafkaTimeout int

// KafkaAutoOffsetReset is kafka offset/reset policy, e.g. latest
var KafkaAutoOffsetReset string

// Kafka TLS-related variables
var KafkaSecurityProtocol string
var KafkaTlsCaLocation string
var KafkaTlsCertLocation string
var KafkaTlsKeyLocation string
var KafkaTlsKeyPassword string

var KnownFsCollections []string

// InitConfig initializes the initial service state, mainly configured through the env variables
func InitConfig(params ...string) {
	var err error

	commitName := NoneValue
	commitSha := NoneValue
	buildDate := NoneValue

	if len(params) >= numOfInitParams {
		commitName = params[0]
		commitSha = params[1]
		buildDate = params[2]
	}

	CommitName = getEnv(commitNameKey, commitName)
	CommitSHA = getEnv(commitSHAKey, commitSha)
	BuildDate = getEnv(buildDateKey, buildDate)

	ServiceName = getEnv(serviceNameKey, DefaultServiceName)
	Env = getEnv(envKey, DefaultEnv)
	WebServerPort = getEnv(webServerPortKey, defaultWebServerPort)

	LogsLevel, err = strconv.Atoi(getEnv(logsLevelKey, defaultLogsLevel))
	if err != nil {
		logError(stringToIntConversionErrMsg, logsLevelKey)
		LogsLevel, _ = strconv.Atoi(defaultLogsLevel)
	}

	GoogleProjectID = getEnv(googleCloudProjectIDKey, defaultGoogleProjectID)
	GoogleAppCreds = getEnv(googleAppCredsKey, defaultGoogleAppCreds)

	// depends on ServiceName and Env, which are set above (do not change order, e.g. move vars around)
	KafkaGroupId = getEnvOrExit(kafkaGroupIdKey)
	KafkaBrokerUrls = getEnvOrExit(kafkaBrokersKey)

	KafkaTimeout, err = strconv.Atoi(getEnv(kafkaConsumerTimeoutKey, defaultKafkaConsumerTimeout))
	if err != nil {
		logError(stringToIntConversionErrMsg, kafkaConsumerTimeoutKey)
		KafkaTimeout, _ = strconv.Atoi(defaultKafkaConsumerTimeout)
	}
	KafkaConsumersNum, err = strconv.Atoi(getEnv(kafkaConsumersNumKey, defaultKafkaConsumersNum))
	if err != nil {
		logError(stringToIntConversionErrMsg, kafkaConsumersNumKey)
		KafkaConsumersNum, _ = strconv.Atoi(defaultKafkaConsumersNum)
	}
	KafkaAutoOffsetReset = getEnv(kafkaAutoOffsetResetKey, defaultKafkaAutoOffsetReset)
	KafkaTopics = getTopics()

	KafkaSecurityProtocol = getEnv(kafkaSecurityProtocolKey, "")
	KafkaTlsCaLocation = getEnv(kafkaTlsCaLocationKey, "")
	KafkaTlsCertLocation = getEnv(kafkaTlsCertLocationKey, "")
	KafkaTlsKeyLocation = getEnv(kafkaTlsKeyLocationKey, "")
	KafkaTlsKeyPassword = getEnv(kafkaTlsKeyPasswordKey, "")

	KnownFsCollections = getKnownCollections()

	// regex
	CompileDeviceServiceRegexes()
	logInfo("%s config has been initialized", ServiceName)
}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return fallback
	}
	return value
}

func createKafkaConsumerId() string {
	return fmt.Sprintf("%s-consumer-%s", ServiceName, Env)
}

func getTopics() []string {
	KafkaFirestoreWriterTopic = getEnv(kafkaFirestoreWriterTopicKey, defaultkafkaFirestoreWriterTopic)
	kafkaTopics := []string{KafkaFirestoreWriterTopic}
	logInfo("kafka topics: %s", KafkaFirestoreWriterTopic)
	return kafkaTopics
}

func getKnownCollections() []string {
	knownCollectionsStr := getEnv(knownFsCollections, defaultKnownFsCollections)
	logInfo("Firestore known collections are %s", knownCollectionsStr)
	return strings.Split(knownCollectionsStr, ",")
}
