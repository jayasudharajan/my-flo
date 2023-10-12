package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/labstack/gommon/log"
)

const commitSHAKey = "COMMIT_SHA"
const commitNameKey = "COMMIT_NAME"
const buildDateKey = "BUILD_DATE"

const serviceNameKey = "SERVICE_NAME"
const envKey = "ENVIRONMENT"

const webServerPortKey = "DS_WEB_SERVER_PORT"

const logsLevelKey = "LOGS_LEVEL"

const dbNameKey = "DS_DB_NAME"
const dbHostKey = "DS_DB_HOST"
const dbPortKey = "DS_DB_PORT"
const dbUserKey = "DS_DB_USER"
const dbPasswordKey = "DS_DB_PASSWORD"
const dbMaxOpenConnectionsKey = "DS_DB_MAX_OPEN_CONNECTIONS"
const dbMaxIdleConnectionsKey = "DS_DB_MAX_IDLE_CONNECTIONS"

const mqttBrokerKey = "DS_MQTT_BROKER"
const mqttDeviceFwPropsTopicTemplateKey = "DS_MQTT_DEVICE_FW_PROPS_TOPIC_TEMPLATE"

const kafkaWorkersNumKey = "DS_WORKERS_NUM"
const numberOfKafkaWorkRequestsPerWorkerKey = "DS_NUM_OF_WORK_REQUESTS_PER_WORKER"
const kafkaBrokersKey = "DS_KAFKA_BROKERS"
const kafkaTimeoutKey = "DS_KAFKA_TIMEOUT"
const kafkaAutoOffsetResetKey = "DS_KAFKA_AUTO_OFFSET_RESET"
const KafkaDevicePropertiesTopicKey = "DS_KAFKA_DEVICE_PROPERTIES_TOPIC"
const kafkaPresenceActivityTopicKey = "DS_KAFKA_PRESENCE_ACTIVITY_TOPIC"
const kafkaConnectivityTopicKey = "DS_KAFKA_CONNECTIVITY_TOPIC"
const kafkaValveStateTopicKey = "DS_KAFKA_VALVE_STATE_TOPIC"
const kafkaZitTopicKey = "DS_KAFKA_ZIT_TOPIC"
const kafkaSystemModeTopicKey = "DS_KAFKA_SYSTEM_MODE_TOPIC"
const kafkaNotificationsTopicKey = "DS_KAFKA_NOTIFICATIONS_TOPIC"
const kafkaEntityActivityTopicKey = "DS_KAFKA_ENTITY_ACTIVITY_TOPIC"
const KafkaOnboardingEventsTopicKey = "DS_KAFKA_ONBOARDING_EVENTS_TOPIC"
const kafkaConsumersNumKey = "DS_KAFKA_CONSUMERS_NUM"

const onboardingToken = "DS_ONBOARDING_API_TOKEN"
const onboardingPath = "DS_ONBOARDING_API_PATH"
const defaultOnboardingApiPath = "/api/v1/onboarding/event/device"
const waterMeterApiPath = "DS_WATER_METER_API_PATH"
const defaultWaterMeterApiPath = "http://flo-water-meter.flo-water-meter.svc.cluster.local"
const offlineTimeThresholdKey = "DS_ONLINE_TIME_THRESHOLD"

const googleCloudProjectIDKey = "GOOGLE_PROJECT_ID"
const googleAppCredsKey = "GCP_SERVICE_ACCOUNT_CREDENTIALS"

const kafkaSecurityProtocolKey = "KAFKA_SECURITY_PROTOCOL"
const kafkaTlsCaLocationKey = "KAFKA_TLS_CA_LOCATION"
const kafkaTlsCertLocationKey = "KAFKA_TLS_CERT_LOCATION"
const kafkaTlsKeyLocationKey = "KAFKA_TLS_KEY_LOCATION"
const kafkaTlsKeyPasswordKey = "KAFKA_TLK_KEY_PASSWORD"

const redisConnectionKey = "REDIS_CONNECTION"

const httpRetryWaitMinKey = "HTTP_RETRY_WAIT_MIN"
const httpRetryWaitMaxKey = "HTTP_RETRY_WAIT_MAX"
const httpMaxRetryNumKey = "HTTP_MAX_RETRY_NUM"
const httpClientSecretKey = "HTTP_CLIENT_SECRET"
const httpClientIdKey = "HTTP_CLIENT_ID"

const floApiUrlKey = "FLO_API_URL"
const firewriterKey = "FIREWRITER_URL"

// ******************** Defaults ********************

const DefaultServiceName = "flo-device-service"
const DefaultEnv = "local"
const defaultWebServerPort = "3000"

// default logs level is set to 2 -> INFO
const defaultLogsLevel = "2"

const defaultDBHost = "dev-rds-cherry.dev.flocloud.co"
const defaultDBPort = "5432"
const defaultDBUser = "flo-device-service"
const defaultDBPassword = "qu3bifTh$dlitotNejShaxye*bkon"
const defaultDBName = "device-service"
const defaultDbMaxIdleConnections = "25"
const defaultDbMaxOpenConnections = "25"

const defaultMqttBroker = "ssl://mqtt-dev.flocloud.co:8883"
const defaultMqttDeviceFwPropsTopicTemplate = "home/device/%s/v1/properties/%s"

const defaultKafkaBrokerURLs = "kafka-cherry-broker-1.dev.flocloud.co:9092,kafka-cherry-broker-2.dev.flocloud.co:9092,kafka-cherry-broker-3.dev.flocloud.co:9092"
const defaultKafkaTimeout = "6000"
const defaultKafkaAutoOffsetReset = "latest"
const defaultConnectivityTopic = "device-connectivity-status-v2"
const defaultDevicePropertiesTopic = "device-properties-pub-v1"
const defaultPresenceActivityTopic = "presence-activity-v1"
const defaultValveStateTopic = "valve-state-v1"
const defaultSystemModeTopic = "system-mode-v1"
const defaultOnboardingEventsTopic = "onboarding-events-v1"
const defaultZitTopic = "zit-v2"
const defaultKafkaNotificationsTopic = "notifications-v2"
const defaultKafkaEntityActivityTopic = "entity-activity-v1"
const defaultKafkaConsumersNum = "1"
const defaultKafkaWorkersNum = "3"
const defaultNumberOfKafkaWorkRequestsPerWorker = "50"

const defaultRedisConnection = "redis-dev-cluster.9alsts.clustercfg.usw2.cache.amazonaws.com:6379"

const defaultFloApiUrl = "https://api-gw-dev.flocloud.co"
const defaultFirewriterUrl = "https://flo-firewriter.flocloud.co"
const defaultHttpRetryWaitMin = "800"
const defaultHttpRetryWaitMax = "1200"
const defaultHttpMaxRetryNum = "3"
const defaultHttpClientSecret = "check 1Password"
const defaultHttpClientId = "check 1Password"

// 300 seconds in between is_connected kafka heartbeat, adding extra 15 for any delay, time mismatch, etc.
const defaultOfflineTimeThreshold = "315"

const defaultGoogleProjectID = "flo-dev-ec388"
const defaultGoogleAppCreds = "creds/flo_ds_service_account_key.json"

const numOfInitParams = 3

const stringToIntConversionErrMsg = "failed to convert %s string value to int"
const fwProperties_TelemetryRealtimeTimeoutKey string = "telemetry_realtime_timeout"
const fwProperties_TelemetryRealtimeTimeoutSeconds int = 300

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

var DbName string
var DbHost string
var DbPort string
var DbUser string
var DbPassword string

// DbMaxIdleConnections is the number of max idle DB connections
var DbMaxIdleConnections int

// DbMaxOpenConnections is the number of max opened DB connections
var DbMaxOpenConnections int

// KafkaBrokerUrls is kafka broker URLs, csv formatted
var KafkaBrokerUrls string

// KafkaGroupId is kafka consumer group ID
var KafkaGroupId string

// KafkaTopics are kafka topics kafka consumer is listening on
var KafkaTopics []string

// KafkaTimeout is kafka consumer timeout
var KafkaTimeout int

// KafkaAutoOffsetReset is kafka offset/reset policy, e.g. latest
var KafkaAutoOffsetReset string

// KafkaConnectivityTopic is kafka FLO device connectivity topic name
var KafkaConnectivityTopic string

// KafkaDevicePropertiesTopic is kafka device properties topic
var KafkaDevicePropertiesTopic string

// KafkaPresenceActivityTopic is the kafka presence activity topic
var KafkaPresenceActivityTopic string

// KafkaValveStateTopic is the kafka valve state topic
var KafkaValveStateTopic string

// KafkaZitTopic is the ZIT test status topic, used for isConnected multiple-signal processing
var KafkaZitTopic string

// KafkaSystemModeTopic is the device system mode, used for isConnected multiple-signal processing
var KafkaSystemModeTopic string

// KafkaNotificationsTopic
var KafkaNotificationsTopic string

// KafkaEntityActivityTopic
var KafkaEntityActivityTopic string

// KafkaOnboardingEventsTopic is kafka onboarding events topic
var KafkaOnboardingEventsTopic string

// KafkaConsumersNum is kafka consumers number
var KafkaConsumersNum int

// KafkaWorkersNum is the number of device service kafka workers
var KafkaWorkersNum int

// NumberOfKafkaWorkRequestsPerWorker is the number of kafka work requests per worker
var NumberOfKafkaWorkRequestsPerWorker int

// GoogleProjectID is the google project ID
var GoogleProjectID string

// GoogleAppCreds is the path to google application credentials file
var GoogleAppCreds string

// OfflineTimeThreshold is the time threshold in seconds for the device considered to be offline if it hasn't been communicating to
// the backend server
var OfflineTimeThreshold int

// MqttBrokerUrl is the MQTT broker connection string
var MqttBrokerUrl string

// MqttDeviceFwPropsTopicTemplate is an MQTT device firmware properties topic template
var MqttDeviceFwPropsTopicTemplate string

// FwPropertyTelemetryTimeoutMsg is message in bytes determining telemetry timeout propertry setting for the device
var FwPropertyTelemetryTimeoutMsg []byte

// Kafka TLS-related variables
var KafkaSecurityProtocol string
var KafkaTlsCaLocation string
var KafkaTlsCertLocation string
var KafkaTlsKeyLocation string
var KafkaTlsKeyPassword string

var RedisConnection string

var HttpRetryWaitMin int
var HttpRetryWaitMax int
var HttpMaxRetryNum int
var HttpClientSecret string
var HttpClientId string

var FloApiUrl string
var OnboardingApiPath string
var WaterMeterApiPath string
var OnboardingApiToken string
var FirewriterUrl string

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
		log.Errorf(stringToIntConversionErrMsg, logsLevelKey)
		LogsLevel, _ = strconv.Atoi(defaultLogsLevel)
	}

	// use default db settings for dev purposes
	DbHost = getEnv(dbHostKey, defaultDBHost)
	DbPort = getEnv(dbPortKey, defaultDBPort)
	DbUser = getEnv(dbUserKey, defaultDBUser)
	DbPassword = getEnv(dbPasswordKey, defaultDBPassword)
	DbName = getEnv(dbNameKey, defaultDBName)

	MqttBrokerUrl = getEnv(mqttBrokerKey, defaultMqttBroker)
	MqttDeviceFwPropsTopicTemplate = getEnv(mqttDeviceFwPropsTopicTemplateKey, defaultMqttDeviceFwPropsTopicTemplate)

	// depends on ServiceName and Env, which are set above (do not change order, e.g. move vars around)
	KafkaGroupId = createKafkaConsumerId()
	KafkaBrokerUrls = getEnv(kafkaBrokersKey, defaultKafkaBrokerURLs)

	KafkaTimeout, err = strconv.Atoi(getEnv(kafkaTimeoutKey, defaultKafkaTimeout))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, kafkaTimeoutKey)
		KafkaTimeout, _ = strconv.Atoi(defaultKafkaTimeout)
	}
	KafkaTopics = getTopics()

	KafkaAutoOffsetReset = getEnv(kafkaAutoOffsetResetKey, defaultKafkaAutoOffsetReset)

	KafkaConsumersNum, err = strconv.Atoi(getEnv(kafkaConsumersNumKey, defaultKafkaConsumersNum))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, kafkaConsumersNumKey)
		KafkaConsumersNum, _ = strconv.Atoi(defaultKafkaConsumersNum)
	}

	KafkaWorkersNum, err = strconv.Atoi(getEnv(kafkaWorkersNumKey, defaultKafkaWorkersNum))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, kafkaWorkersNumKey)
		KafkaWorkersNum, _ = strconv.Atoi(defaultKafkaWorkersNum)
	}

	NumberOfKafkaWorkRequestsPerWorker, err = strconv.Atoi(getEnv(numberOfKafkaWorkRequestsPerWorkerKey,
		defaultNumberOfKafkaWorkRequestsPerWorker))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, numberOfKafkaWorkRequestsPerWorkerKey)
		NumberOfKafkaWorkRequestsPerWorker, _ = strconv.Atoi(defaultNumberOfKafkaWorkRequestsPerWorker)
	}

	OfflineTimeThreshold, err = strconv.Atoi(getEnv(offlineTimeThresholdKey, defaultOfflineTimeThreshold))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, offlineTimeThresholdKey)
		OfflineTimeThreshold, _ = strconv.Atoi(defaultOfflineTimeThreshold)
	}
	DbMaxIdleConnections, err = strconv.Atoi(getEnv(dbMaxIdleConnectionsKey, defaultDbMaxIdleConnections))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, dbMaxIdleConnectionsKey)
		DbMaxIdleConnections, _ = strconv.Atoi(defaultDbMaxIdleConnections)
	}
	DbMaxOpenConnections, err = strconv.Atoi(getEnv(dbMaxOpenConnectionsKey, defaultDbMaxOpenConnections))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, dbMaxOpenConnectionsKey)
		DbMaxOpenConnections, _ = strconv.Atoi(defaultDbMaxOpenConnections)
	}

	GoogleProjectID = getEnv(googleCloudProjectIDKey, defaultGoogleProjectID)
	GoogleAppCreds = getEnv(googleAppCredsKey, defaultGoogleAppCreds)

	KafkaSecurityProtocol = getEnv(kafkaSecurityProtocolKey, EmptyString)
	KafkaTlsCaLocation = getEnv(kafkaTlsCaLocationKey, EmptyString)
	KafkaTlsCertLocation = getEnv(kafkaTlsCertLocationKey, EmptyString)
	KafkaTlsKeyLocation = getEnv(kafkaTlsKeyLocationKey, EmptyString)
	KafkaTlsKeyPassword = getEnv(kafkaTlsKeyPasswordKey, EmptyString)

	RedisConnection = getEnv(redisConnectionKey, defaultRedisConnection)

	FloApiUrl = getEnv(floApiUrlKey, defaultFloApiUrl)
	OnboardingApiPath = getEnv(onboardingPath, defaultOnboardingApiPath)
	WaterMeterApiPath = getEnv(waterMeterApiPath, defaultWaterMeterApiPath)
	OnboardingApiToken = getEnv(onboardingToken, "")
	if OnboardingApiToken == "" {
		log.Warn("onboardingToken is blank")
	}

	FirewriterUrl = getEnv(firewriterKey, defaultFirewriterUrl)

	HttpRetryWaitMin, err = strconv.Atoi(getEnv(httpRetryWaitMinKey, defaultHttpRetryWaitMin))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, httpRetryWaitMinKey)
		HttpRetryWaitMin, _ = strconv.Atoi(defaultHttpRetryWaitMin)
	}
	HttpRetryWaitMax, err = strconv.Atoi(getEnv(httpRetryWaitMaxKey, defaultHttpRetryWaitMax))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, httpRetryWaitMaxKey)
		HttpRetryWaitMax, _ = strconv.Atoi(defaultHttpRetryWaitMax)
	}
	HttpMaxRetryNum, err = strconv.Atoi(getEnv(httpMaxRetryNumKey, defaultHttpMaxRetryNum))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, httpMaxRetryNumKey)
		HttpMaxRetryNum, _ = strconv.Atoi(defaultHttpMaxRetryNum)
	}
	HttpClientSecret = getEnv(httpClientSecretKey, defaultHttpClientSecret)
	HttpClientId = getEnv(httpClientIdKey, defaultHttpClientId)

	// compile FwPropertyTelemetryTimeoutMsg
	FwPropertyTelemetryTimeoutMsg, err = compileTelemetryTimeoutMsg()
	if err != nil {
		log.Errorf("failed to compile firmware property %s", fwProperties_TelemetryRealtimeTimeoutKey)
	}

	// regex
	CompileDeviceServiceRegexes()
	log.Infof("%s config has been initialized", ServiceName)
}

func getTopics() []string {
	KafkaConnectivityTopic = getEnv(kafkaConnectivityTopicKey, defaultConnectivityTopic)
	KafkaDevicePropertiesTopic = getEnv(KafkaDevicePropertiesTopicKey, defaultDevicePropertiesTopic)
	KafkaPresenceActivityTopic = getEnv(kafkaPresenceActivityTopicKey, defaultPresenceActivityTopic)
	KafkaValveStateTopic = getEnv(kafkaValveStateTopicKey, defaultValveStateTopic)
	KafkaZitTopic = getEnv(kafkaZitTopicKey, defaultZitTopic)
	KafkaSystemModeTopic = getEnv(kafkaSystemModeTopicKey, defaultSystemModeTopic)
	KafkaNotificationsTopic = getEnv(kafkaNotificationsTopicKey, defaultKafkaNotificationsTopic)
	KafkaEntityActivityTopic = getEnv(kafkaEntityActivityTopicKey, defaultKafkaEntityActivityTopic)
	KafkaOnboardingEventsTopic = getEnv(KafkaOnboardingEventsTopicKey, defaultOnboardingEventsTopic)

	KafkaTopics := []string{
		KafkaDevicePropertiesTopic,
		KafkaPresenceActivityTopic,
		KafkaValveStateTopic,
		KafkaSystemModeTopic,
		KafkaEntityActivityTopic,
		KafkaOnboardingEventsTopic,
	}

	log.Infof("kafka topics: %s", strings.Join(KafkaTopics, ","))
	return KafkaTopics
}

func createKafkaConsumerId() string {
	return fmt.Sprintf("%s-consumer-%s", ServiceName, Env)
}

func compileTelemetryTimeoutMsg() ([]byte, error) {
	msg := make(map[string]int)
	msg[fwProperties_TelemetryRealtimeTimeoutKey] = fwProperties_TelemetryRealtimeTimeoutSeconds
	return json.Marshal(msg)
}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return fallback
	}
	return value
}
