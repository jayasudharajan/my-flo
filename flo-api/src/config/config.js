'use strict'

/*
import path from 'path';
import _ from 'lodash';
import os from 'os';
*/

var path = require('path');
var _ = require('lodash');
var os = require('os');
var konfig = require('konphyg')(__dirname).all().main;

// Hack - remove function from konphyg JSON.
delete konfig._merge;

// OS level config.
let rootPath = path.normalize(__dirname + '/..');
let env = process.env.NODE_ENV || 'undefined';
let enforceHttps = process.env.ENFORCE_HTTPS || true;
let workers = os.cpus().length || 1;
let confidentialFields = [
      'address',
      'address2',
      'city',
      'country',
      'location_type',
      'postalcode',
      'state',
      'timezone',
      'icd_client_key',
      'icd_client_cert',
      'icd_login_token',
      'icd_websocket_cert',
      'icd_websocket_cert_der',
      'icd_websocket_key',
      'wifi_password',
      'firstname',
      'lastname',
      'middlename',
      'phone_mobile',
      'email',
      'password',
      'username',
      'password_conf',
      'token',
      'client_secret',
      'mfa_token',
      'code',
      'stripe_token',
      'old_pass',
      'new_pass',
      'new_pass_conf'
];

let config = {
  all: {
    env: env,
    enforceHttps: (enforceHttps == 'true'),
    root: rootPath,
    numberOfWorkers: workers,
    port: process.env.FLO_API_PORT || 8000,
    confidentialFields: confidentialFields,
    appName: 'flo-public-api-v1'
  }
};

// Combine all config params.
// NOTE: using ES5 style to support command line tasks.
module.exports = mergeEnv();
//export default mergeEnv();

/**
 * If ENV variables exists, overwrite in config.
 * @return {Object} config JSON.
 */
function mergeEnv() {
  // TOKEN
  if(process.env.FLO_API_CRYPTOPASSWORD) {
    konfig.cryptoPassword = process.env.FLO_API_CRYPTOPASSWORD;
  }

  if(process.env.FLO_API_TOKENSECRET) {
    konfig.tokenSecret = process.env.FLO_API_TOKENSECRET;
  }

  if(process.env.FLO_API_TOKEN_EXPIRATION) {
    konfig.tokenExpirationTimeInSeconds = process.env.FLO_API_TOKEN_EXPIRATION;
  }

  if(process.env.FLO_API_AWS_DYNAMODB_REGION) {
    konfig.aws.dynamodb.region = process.env.FLO_API_AWS_DYNAMODB_REGION;
  }

  if(process.env.FLO_API_AWS_DYNAMODB_ENDPOINT) {
    konfig.aws.dynamodb.endpoint = process.env.FLO_API_AWS_DYNAMODB_ENDPOINT;
  }

  if(process.env.FLO_API_AWS_DYNAMODB_PREFIX) {
    konfig.aws.dynamodb.prefix = process.env.FLO_API_AWS_DYNAMODB_PREFIX;
  }

  if(process.env.FLO_API_AWS_API_VERSION) {
    konfig.aws.apiVersion = process.env.FLO_API_AWS_API_VERSION;
  }

  if (process.env.FLO_API_ELASTICACHE_ENDPOINT) {
    konfig.redis.url = process.env.FLO_API_ELASTICACHE_ENDPOINT;
  }

  if (process.env.FLO_API_SENDWITHUS_API_KEY) {
    konfig.email.sendwithus.api_key = process.env.FLO_API_SENDWITHUS_API_KEY;
  }

  // influxdb Settings
  if(process.env.FLO_API_INFLUXDB_HOST) {
    konfig.influxdb.host = process.env.FLO_API_INFLUXDB_HOST;
  }

  if(process.env.FLO_API_INFLUXDB_PORT) {
    konfig.influxdb.port = process.env.FLO_API_INFLUXDB_PORT;
  }

  if (process.env.FLO_API_INFLUXDB_DATABASE) {
    konfig.influxdb.database = process.env.FLO_API_INFLUXDB_DATABASE;
  }

  if (process.env.FLO_API_INFLUXDB_ANALYTICS_DATABASE) {
    konfig.influxdb.analyticsDatabase = process.env.FLO_API_INFLUXDB_ANALYTICS_DATABASE;
  }

  if (process.env.FLO_API_INFLUXDB_TELEMETRY_HOURLY_MEASUREMENT) {
    konfig.influxdb.telemetryHourlyMeasurement = process.env.FLO_API_INFLUXDB_TELEMETRY_HOURLY_MEASUREMENT;
  }

  if (process.env.FLO_API_INFLUXDB_TELEMETRY_15M_MEASUREMENT) {
    konfig.influxdb.telemetry15mMeasurement = process.env.FLO_API_INFLUXDB_TELEMETRY_15M_MEASUREMENT;
  }

  if (process.env.FLO_API_INFLUXDB_RAW_TELEMETRY_MEASUREMENT) {
    konfig.influxdb.rawTelemetryMeasurement = process.env.FLO_API_INFLUXDB_RAW_TELEMETRY_MEASUREMENT;
  }

  if (process.env.FLO_API_INFLUXDB_USER) {
    konfig.influxdb.username = process.env.FLO_API_INFLUXDB_USER;
  }

  if (process.env.FLO_API_INFLUXDB_PASSWORD) {
    konfig.influxdb.password = process.env.FLO_API_INFLUXDB_PASSWORD;
  }

  if (process.env.FLO_API_KAFKA_HOST) {
    konfig.kafkaHost = process.env.FLO_API_KAFKA_HOST;
  }

  if (process.env.FLO_API_CLIENT_CERT) {
    konfig.clientCertificatePath = process.env.FLO_API_CLIENT_CERT;
  }

  if (process.env.FLO_API_CLIENT_KEY) {
    konfig.clientKeyPath = process.env.FLO_API_CLIENT_KEY;
  }

  if (process.env.FLO_API_MQTT_CAFILE) {
    konfig.mqttBroker.caFilePath = process.env.FLO_API_MQTT_CAFILE;
  }

  if (process.env.FLO_API_MQTT_CAFILE_V2) {
    konfig.mqttBroker.caV2FilePath = process.env.FLO_API_MQTT_CAFILE_V2;
  }

  if (process.env.FLO_API_CERT_BUCKET) {
    konfig.certBucket = process.env.FLO_API_CERT_BUCKET;
  }

  if (process.env.FLO_API_MQTT_BROKER_HOST) {
    konfig.mqttBroker.host = process.env.FLO_API_MQTT_BROKER_HOST;
  }

  if (process.env.FLO_API_MQTT_BROKER_PORT) {
    konfig.mqttBroker.port = process.env.FLO_API_MQTT_BROKER_PORT;
  }

  if (process.env.FLO_API_KEY_PROVIDER_BUCKET_REGION) {
    konfig.encryption.bucketRegion = process.env.FLO_API_KEY_PROVIDER_BUCKET_REGION;
  }

  if (process.env.FLO_API_KEY_PROVIDER_BUCKET_NAME) {
    konfig.encryption.bucketName = process.env.FLO_API_KEY_PROVIDER_BUCKET_NAME;
  }

  if (process.env.FLO_API_KAFKA_PROVIDER_KEY_PATH_TEMPLATE) {
    konfig.encryption.kafka.keyPathTemplate = process.env.FLO_API_KAFKA_PROVIDER_KEY_PATH_TEMPLATE;
  }

  if (process.env.FLO_API_KAFKA_KEY_ID) {
    konfig.encryption.kafka.keyId = process.env.FLO_API_KAFKA_KEY_ID;
  }

  if (process.env.FLO_API_KAFKA_ENCRYPTION_ENABLED) {
    konfig.encryption.kafka.encryptionEnabled = JSON.parse(process.env.FLO_API_KAFKA_ENCRYPTION_ENABLED);
  }

  if (process.env.FLO_API_DYNAMODB_PROVIDER_KEY_PATH_TEMPLATE) {
    konfig.encryption.dynamodb.keyPathTemplate = process.env.FLO_API_DYNAMODB_PROVIDER_KEY_PATH_TEMPLATE;
  }

  if (process.env.FLO_API_DYNAMODB_KEY_ID) {
    konfig.encryption.dynamodb.keyId = process.env.FLO_API_DYNAMODB_KEY_ID;
  }

  if (process.env.FLO_API_DYNAMODB_ENCRYPTION_ENABLED) {
    konfig.encryption.dynamodb.encryptionEnabled = JSON.parse(process.env.FLO_API_DYNAMODB_ENCRYPTION_ENABLED);
  }

  if (process.env.FLO_API_HMAC_KEY) {
    konfig.encryption.hmacKey = process.env.FLO_API_HMAC_KEY;
  }

  if (process.env.FLO_API_PES) {
    konfig.pes = process.env.FLO_API_PES;
  }

  if (process.env.MOBILE_REGISTRATION_URL) {
    konfig.mobile_registration_url = process.env.MOBILE_REGISTRATION_URL;
  }

  if (process.env.FLO_API_PKI_KAFKA_TOPIC) {
    konfig.pkiKafkaTopic = process.env.FLO_API_PKI_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_PKI_REMOVE_DEVICE_KAFKA_TOPIC) {
    konfig.pkiRemoveDeviceKafkaTopic = process.env.FLO_API_PKI_REMOVE_DEVICE_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_PKI_GENERATION_VERSION) {
    konfig.pkiGenerationVersion = process.env.FLO_API_PKI_GENERATION_VERSION;
  }

  if (process.env.FLO_API_DIRECTIVES_KAFKA_TOPIC) {
    konfig.directivesKafkaTopic = process.env.FLO_API_DIRECTIVES_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_NOTIFICATIONS_KAFKA_TOPIC) {
    konfig.notificationsKafkaTopic = process.env.FLO_API_NOTIFICATIONS_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_ADMIN_URL) {
    konfig.admin_url = process.env.FLO_API_ADMIN_URL;
  }

  if (process.env.FLO_API_USER_URL) {
    konfig.user_url = process.env.FLO_API_USER_URL;
  }

  if (process.env.FLO_API_USER_PORTAL_URL) {
    konfig.user_portal_url = process.env.FLO_API_USER_PORTAL_URL;
  }

  if (process.env.FLO_API_MUD_URL) {
    konfig.mud_url = process.env.FLO_API_MUD_URL;
  }

  if (process.env.FLO_API_MAX_LOGIN_ATTEMPTS) {
    konfig.maxFailedLoginAttempts = process.env.FLO_API_MAX_LOGIN_ATTEMPTS;
  }

  if (process.env.FLO_API_LOGIN_ATTEMPTS_MINUTES) {
    konfig.failedLoginAttemptsMinutes = process.env.FLO_API_LOGIN_ATTEMPTS_MINUTES;
  }

  if(process.env.NOT_FORCE_UPDATE_FOR_MOBILE_APP_IOS_VERSIONS){
    konfig.notForceUpdateForMobileAppIosVersions = process.env.NOT_FORCE_UPDATE_FOR_MOBILE_APP_IOS_VERSIONS;
  }

  if(process.env.LATEST_APP_VERSION_IOS){
    konfig.latestAppVersionIos = process.env.LATEST_APP_VERSION_IOS;
  }

  if(process.env.LATEST_APP_VERSION_APP_STORE_URL){
    konfig.latestAppVersionAppStoreUrl = process.env.LATEST_APP_VERSION_APP_STORE_URL;
  }

  if(process.env.FLO_API_FLO_DEVICE_DEFAULT_WEBSOCKET_TOKEN){
    konfig.floDeviceDefaultWebsocketToken = process.env.FLO_API_FLO_DEVICE_DEFAULT_WEBSOCKET_TOKEN;
  }
  if(process.env.FLO_API_ELASTICSEARCH_HOST){
    konfig.elasticSearchHost = process.env.FLO_API_ELASTICSEARCH_HOST;
  }
  if (process.env.FLO_API_INFLUXDB_TELEMETRY_HOURLY_PATH) {
    konfig.influxdb.telemetryHourlyPath = process.env.FLO_API_INFLUXDB_TELEMETRY_HOURLY_PATH;
  }

  if (process.env.FLO_API_TWILIO_AUTH_TOKEN) {
    konfig.twilioAuthToken = process.env.FLO_API_TWILIO_AUTH_TOKEN;
  }

  if (process.env.FLO_API_TWILIO_ACCOUNT_SID) {
    konfig.twilioAccountSid = process.env.FLO_API_TWILIO_ACCOUNT_SID;
  }

  if (process.env.FLO_API_VOICE_CALL_MAIN_MENU_URL) {
    konfig.voiceCallMainMenuUrl = process.env.FLO_API_VOICE_CALL_MAIN_MENU_URL;
  }

  if (process.env.FLO_API_VOICE_CALL_OPTION_0_AUDIO) {
    konfig.voiceCallOption0Audio = process.env.FLO_API_VOICE_CALL_OPTION_0_AUDIO;
  }

  if (process.env.FLO_API_VOICE_CALL_OPTION_1_AUDIO) {
    konfig.voiceCallOption1Audio = process.env.FLO_API_VOICE_CALL_OPTION_1_AUDIO;
  }

  if (process.env.FLO_API_VOICE_CALL_OPTION_2_AUDIO) {
    konfig.voiceCallOption2Audio = process.env.FLO_API_VOICE_CALL_OPTION_2_AUDIO;
  }

  if (process.env.FLO_API_VOICE_CALL_HOME_WRONG_INPUT_URL) {
    konfig.voiceCallHomeWrongInputUrl = process.env.FLO_API_VOICE_CALL_HOME_WRONG_INPUT_URL;
  }

  if (process.env.FLO_API_VOICE_CALL_AWAY_WRONG_INPUT_URL) {
    konfig.voiceCallAwayWrongInputUrl = process.env.FLO_API_VOICE_CALL_AWAY_WRONG_INPUT_URL;
  }

  if (process.env.FLO_API_CUSTOMER_CARE_PHONE) {
    konfig.customerCarePhone = process.env.FLO_API_CUSTOMER_CARE_PHONE;
  }

  if (process.env.FLO_API_ACCESS_TOKEN_TTL) {
    konfig.accessTokenTTL = process.env.FLO_API_ACCESS_TOKEN_TTL;
  }

  if (process.env.FLO_API_REFRESH_TOKEN_TTL) {
    konfig.refreshTokenTTL = process.env.FLO_API_REFRESH_TOKEN_TTL;
  }

  if (process.env.FLO_API_REFRESH_TOKEN_LIMIT) {
    konfig.refreshTokenLimit = process.env.FLO_API_REFRESH_TOKEN_LIMIT;
  }

  if (process.env.FLO_API_REFRESH_TOKEN_LINGER) {
    konfig.refreshTokenLinger = process.env.FLO_API_REFRESH_TOKEN_LINGER;
  }

  if (process.env.FLO_API_REGISTRATION_SESSION_TTL) {
    konfig.registrationSessionTTL = process.env.FLO_API_REGISTRATION_SESSION_TTL;
  }

  if (process.env.FLO_API_REGISTRATION_EMAIL_TEMPLATE_ID) {
    konfig.registrationEmailTemplateId = process.env.FLO_API_REGISTRATION_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_API_WEB_REGISTRATION_EMAIL_TEMPLATE_ID) {
    konfig.webRegistrationEmailTemplateId = process.env.FLO_API_WEB_REGISTRATION_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_API_ORDER_PAYMENT_COMPLETED_EMAIL_TEMPLATE_ID) {
    konfig.orderPaymentCompletedEmailTemplateId = process.env.FLO_API_ORDER_PAYMENT_COMPLETED_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_API_SHOPIFY_SECRET_KEY) {
    konfig.shopifySecretKey = process.env.FLO_API_SHOPIFY_SECRET_KEY;
  }

  if (process.env.FLO_EMAIL_SERVICE_TOPIC) {
    konfig.emailServiceTopic = process.env.FLO_EMAIL_SERVICE_TOPIC;
  }

  if (process.env.FLO_PAIRING_EMAIL_TEMPLATE_ID) {
    konfig.pairingEmailTemplateId = process.env.FLO_PAIRING_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_PAIRING_NO_INSTALL_EMAIL_TEMPLATE_ID) {
    konfig.getPairingNoInstallTemplateId = process.env.FLO_PAIRING_NO_INSTALL_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_INSTALLATION_EMAIL_TEMPLATE_ID) {
    konfig.installationTemplateId = process.env.FLO_INSTALLATION_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_INSTALLATION_3_DAYS_AFTER_EMAIL_TEMPLATE_ID) {
    konfig.installation3DaysAfterEmailTemplateId = process.env.FLO_INSTALLATION_3_DAYS_AFTER_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_INSTALLATION_21_DAYS_AFTER_EMAIL_TEMPLATE_ID) {
    konfig.installation21DaysAfterEmailTemplateId = process.env.FLO_INSTALLATION_21_DAYS_AFTER_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_SYSTEM_MODE_UNLOCKED_EMAIL_TEMPLATE_ID) {
    konfig.systemModeUnlockedTemplateId = process.env.FLO_SYSTEM_MODE_UNLOCKED_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_REPORT_KAFKA_TOPIC) {
    konfig.reportKafkaTopic = process.env.FLO_REPORT_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_MAGIC_LINK_EMAIL_TEMPLATE_ID) {
    konfig.magicLinkEmailTemplateId = process.env.FLO_API_MAGIC_LINK_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_API_PASSWORDLESS_REDIRECT_URL) {
    konfig.passwordlessRedirectURL = process.env.FLO_API_PASSWORDLESS_REDIRECT_URL;
  }

  if (process.env.FLO_API_MAGIC_LINK_MOBILE_URI) {
    konfig.magicLinkMobileURI = process.env.FLO_API_MAGIC_LINK_MOBILE_URI;
  }

  if (process.env.FLO_API_OAUTH2_CLIENT_ID) {
    konfig.oauth2ClientId = process.env.FLO_API_OAUTH2_CLIENT_ID;
  }

  if (process.env.FLO_API_LEGACY_AUTH_DISABLED) {
    konfig.legacyAuthDisabled = process.env.FLO_API_LEGACY_AUTH_DISABLED;
  }

  if (process.env.FLO_API_FIXTURE_DETECTION_KAFKA_TOPIC) {
    konfig.fixtureDetectionKafkaTopic = process.env.FLO_API_FIXTURE_DETECTION_KAFKA_TOPIC;
  }

  if (process.env.FLO_API_MFA_TOKEN_TTL) {
    konfig.mfaTokenTTL = process.env.FLO_API_MFA_TOKEN_TTL;
  }

  if (process.env.FLO_API_STRIPE_SECRET_KEY) {
    konfig.stripeSecretKey = process.env.FLO_API_STRIPE_SECRET_KEY;
  }

  if (process.env.FLO_API_STRIPE_WEBHOOK_SIGNATURE_SECRET) {
    konfig.stripeWebhookSignatureSecret = process.env.FLO_API_STRIPE_WEBHOOK_SIGNATURE_SECRET;
  }

  if (process.env.FLO_API_SUBSCRIPTION_DEFAULT_PLAN_ID) {
    konfig.subscriptionDefaultPlanId = process.env.FLO_API_SUBSCRIPTION_DEFAULT_PLAN_ID;
  }

  if (process.env.FLO_API_SUBSCRIPTION_DEFAULT_SOURCE_ID) {
    konfig.subscriptionDefaultSourceId = process.env.FLO_API_SUBSCRIPTION_DEFAULT_SOURCE_ID;
  }
  if (process.env.FLO_API_DEVICE_ANOMALY_EMAIL_TEMPLATE_ID) {
    konfig.deviceAnomalyTemplateId = process.env.FLO_API_DEVICE_ANOMALY_EMAIL_TEMPLATE_ID;
  }
  if (process.env.FLO_API_CS_EMAIL_ADDRESS) {
    konfig.customerServiceEmail = process.env.FLO_API_CS_EMAIL_ADDRESS;
  }

  if (process.env.FLO_API_APPS_CONFIG_BUCKET) {
    konfig.appsConfigBucket = process.env.FLO_API_APPS_CONFIG_BUCKET;
  }

  if (process.env.FLO_API_DEVICE_PRESENCE_FIREBASE_ADMIN_CREDENTIALS_PATH) {
    konfig.devicePresenceFirebaseAdminCredentialsPath = process.env.FLO_API_DEVICE_PRESENCE_FIREBASE_ADMIN_CREDENTIALS_PATH;
  }

  if (process.env.FLO_API_DEVICE_PRESENCE_DATABASE_URL) {
    konfig.devicePresenceDatabaseUrl = process.env.FLO_API_DEVICE_PRESENCE_DATABASE_URL;
  }

  if (process.env.FLO_API_QR_CODES_BUCKET) {
    konfig.qrCodesBucket = process.env.FLO_API_QR_CODES_BUCKET;
  }

  if (process.env.FLO_API_QR_CODES_PATH_TEMPLATE) {
    konfig.qrCodesPathTemplate = process.env.FLO_API_QR_CODES_PATH_TEMPLATE;
  }

  if (process.env.FLO_API_IFTTT_SERVICE_KEY) {
    konfig.iftttServiceKey = process.env.FLO_API_IFTTT_SERVICE_KEY;
  }

  if (process.env.FLO_API_IFTTT_CLIENT_ID) {
    konfig.iftttClientId = process.env.FLO_API_IFTTT_CLIENT_ID;
  }

  if (process.env.FLO_API_IFTTT_REALTIME_URL) {
    konfig.iftttRealtimeNotificationsUrl = process.env.FLO_API_IFTTT_REALTIME_URL;
  }

  if (process.env.FLO_API_POSTGRES_USER) {
    konfig.postgresUser = process.env.FLO_API_POSTGRES_USER;
  }

  if (process.env.FLO_API_POSTGRES_PASSWORD) {
    konfig.postgresPassword = process.env.FLO_API_POSTGRES_PASSWORD;
  }

  if (process.env.FLO_API_POSTGRES_HOST) {
    konfig.postgresHost = process.env.FLO_API_POSTGRES_HOST;
  }

  if (process.env.FLO_API_POSTGRES_PORT) {
    konfig.postgresPort = process.env.FLO_API_POSTGRES_PORT;
  }

  if (process.env.FLO_API_POSTGRES_DATABASE) {
    konfig.postgresDatabase = process.env.FLO_API_POSTGRES_DATABASE;
  }

  if (process.env.FLO_API_AWAY_MODE_LAMBDA) {
    konfig.irrigationScheduleLambda = process.env.FLO_API_AWAY_MODE_LAMBDA;
  }

  if (process.env.FLO_INSURANCE_LETTER_GENERATION_LAMBDA) {
    konfig.insuranceLetterGenerationLambda = process.env.FLO_INSURANCE_LETTER_GENERATION_LAMBDA;
  }

  if (process.env.FLO_API_ADMIN_IP_WHITELIST) {
    konfig.adminIpAddressWhitelist = process.env.FLO_API_ADMIN_IP_WHITELIST;
  }

  if (process.env.FLO_API_FLO_DETECT_MIN_INSTALL_DAYS) {
    konfig.floDetectMinimumDaysInstalled = process.env.FLO_API_FLO_DETECT_MIN_INSTALL_DAYS;
  }

  if (process.env.FLO_API_GOOGLE_HOME_TOKEN_PROVIDER_BUCKET) {
    konfig.googleHomeTokenProviderBucket = process.env.FLO_API_GOOGLE_HOME_TOKEN_PROVIDER_BUCKET;
  }

  if (process.env.FLO_API_GOOGLE_HOME_TOKEN_PROVIDER_KEY) {
    konfig.googleHomeTokenProviderKey = process.env.FLO_API_GOOGLE_HOME_TOKEN_PROVIDER_KEY;
  }

  if (process.env.FLO_API_CLIENT_IDS) {
    // Format: PascalCaseName:ID,PascalCaseName:ID
    // E.g: GoogleSmartHome:b217963b-faf1-4550-8b18-72cf7e46d8a3,AmazonAlexa:d2501777-6f71-46c7-94c8-fb0292d29dbd
    konfig.clientIds = process.env.FLO_API_CLIENT_IDS;
  }

  if (process.env.FLO_API_EVENTS_ACK_TOPIC) {
    konfig.eventsAckTopic = process.env.FLO_API_EVENTS_ACK_TOPIC;
  }

  if (process.env.FLO_API_INSTALLED_ALERT_ID) {
    konfig.installedAlertId = process.env.FLO_API_INSTALLED_ALERT_ID;
  }

  if (process.env.FLO_API_NOTIFICATION_API_URL) {
    konfig.notificationApiUrl = process.env.FLO_API_NOTIFICATION_API_URL;
  }

  if (process.env.DYNAMODB_TIMEOUT_MS) {
    konfig.aws.timeoutMs = process.env.DYNAMODB_TIMEOUT_MS;
  }

  if (process.env.FLO_API_FR_REGISTRATION_EMAIL_TEMPLATE_ID) {
    konfig.frenchMobileEmailTemplateId = process.env.FLO_API_FR_REGISTRATION_EMAIL_TEMPLATE_ID;
  }

  if (process.env.FLO_API_HOST) {
    konfig.apiHost = process.env.FLO_API_HOST;
  }

  if (process.env.FLO_API_WATER_METER_URL) {
    konfig.waterMeterUrl = process.env.FLO_API_WATER_METER_URL;
  }

  if (process.env.FLO_API_DEVICE_HEARTBEAT_URL) {
    konfig.deviceHeartbeatUrl = process.env.FLO_API_DEVICE_HEARTBEAT_URL;
  }

  if (process.env.VOICE_GATHER_ACTION_URL) {
    konfig.voiceGatherActionUrl = process.env.VOICE_GATHER_ACTION_URL;
  }

  if (process.env.FLO_TASK_SCHEDULER_URL) {
    konfig.taskSchedulerUrl = process.env.FLO_TASK_SCHEDULER_URL;
  }

  konfig.loginOtpUrl = '/api/v1/mfa/login';

  const complete_config = _.extend(
    config.all,
    konfig || {}
  );

  return complete_config;
}
