const util = require('./util');

exports.createAlarmNotificationDeliveryFilterLog = createAlarmNotificationDeliveryFilterLog;
exports.createICDAlarmIncidentRegistry = createICDAlarmIncidentRegistry;
exports.createICDAlarmIncidentRegistryLog = createICDAlarmIncidentRegistryLog;
exports.createICD = createICD;
exports.createAlert = createAlert;
exports.createStockICDLog = createStockICDLog;

function createAlarmNotificationDeliveryFilterLog(alarmNotificationDeliveryFilter, account, location, onboarding) {
	return Object.assign(
		!location ? {} : { geo_location: util.createGeoLocation(location) },
		!account ? {} : { account: util.createAccount(account) },
		!onboarding ? {} : { onboarding: onboarding },
		alarmNotificationDeliveryFilter,
		ensureInt(alarmNotificationDeliveryFilter, [
			'alarm_id',
			'system_mode',
			'severity',
			'status'
		])
	);
}

function createICDAlarmIncidentRegistry(icdAlarmIncidentRegistry, account, location, onboarding) {
	return Object.assign(
		{},
		util.omit(icdAlarmIncidentRegistry, ['account_id']),
		!location ? {} : { geo_location: util.createGeoLocation(location) },
		!account ? {} : { account: util.createAccount(account) },
		ensureInt(icdAlarmIncidentRegistry, ['alarm_id', 'severity']),
		!onboarding ? {} : { onboarding: onboarding }
	);
}

function createICDAlarmIncidentRegistryLog(icdAlarmIncidentRegistryLog, account, location, onboarding) {
	return Object.assign(
		{},
		util.pick(icdAlarmIncidentRegistryLog, [
			'created_at',
			'icd_alarm_incident_registry_id',
			'id',
			'receipt_id',
			'user_id'
		]),
		ensureInt(icdAlarmIncidentRegistryLog, [
			'status',
			'delivery_medium'
		]),
		!location ? {} : { geo_location: util.createGeoLocation(location) },
		!account ? {} : { account: util.createAccount(account) },
		!onboarding ? {} : { onboarding: onboarding }
	);
}

function createICD(data) {
	const icd = data.icd;
	const location = data.location;
	const account = data.account;
	const users = data.users;
	const subscription = data.subscription;

	return Object.assign(
		!icd ? {} : util.pick(icd, ['id', 'device_id', 'is_paired', 'is_test_device']),
		!location ? {} : { geo_location: util.createGeoLocation(location) },
		!account ? {} : { account: util.createAccount(account, subscription), owner_user_id: account.owner_user_id },
		!users ? {} : { users: users },
		!subscription || account ? {} : { account: { subscription: util.createSubscription(subscription) } }
	);
}

function createAlert(data) {
	const alarmNotificationDeliveryFilter = data.alarmNotificationDeliveryFilter;
	const icdAlarmIncidentRegistry = data.icdAlarmIncidentRegistry;
	const icdAlarmNotificationDeliveryRule = Object.assign(
		{ has_alarm_feedback: false },
		data.icdAlarmNotificationDeliveryRule
	);
	const location = data.location;
	const account = data.account;
	const onboarding = data.onboardingLog;
	const user_delivery_media = (data.userAlarmNotificationDeliveryRules || [])
		.map(userAlarmNotificationDeliveryRule => util.pick(
			userAlarmNotificationDeliveryRule,
			[
				'user_id',
				{ optional: 'delivery_media' }
			]
		));
	const is_cleared = 
		(alarmNotificationDeliveryFilter || {}).status != 3 || 
		(icdAlarmIncidentRegistry || {}).acknowledged_by_user == 1 ||
		(icdAlarmIncidentRegistry || {}).self_resolved == 1;

	const doc = Object.assign(
		{ is_cleared },
		!alarmNotificationDeliveryFilter ? 
			{} : 
			util.pick(alarmNotificationDeliveryFilter, [
				'icd_id',
				{ last_icd_alarm_incident_registry_id: 'incident_id' },
				'alarm_id',
				'system_mode',
				'updated_at',
				'incident_time',
				'severity',
				'status',
				'alarm_id_system_mode'
			]),
		!icdAlarmIncidentRegistry ?
			{} :
			util.pick(icdAlarmIncidentRegistry, [
				{ id: 'incident_id' },
				'user_action_taken',
				'acknowledged_by_user',
				'self_resolved',
				'self_resolved_message',
				'telemetry_data',
				'incident_time',
				'friendly_name',
				'friendly_description'
			]),
		!icdAlarmNotificationDeliveryRule ? 
			{} :
			util.pick(icdAlarmNotificationDeliveryRule, [
				'user_actions',
				{ mandatory: 'default_delivery_media' },
				'has_alarm_feedback'
			]),
		!location ? {} : { geo_location: util.createGeoLocation(location) },
		!account ? {} : { account : util.createAccount(account) },
		!user_delivery_media || !user_delivery_media.length ? {} : { user_delivery_media },
		!onboarding ? {} : { onboarding: onboarding }
	);

	return ensureInt(doc, ['alarm_id', 'system_mode', 'acknowledged_by_user', 'self_resolved']);
}

function createStockICDLog(stockICD, event) {
	return Object.assign({ event }, stockICD);
}

function ensureInt(object, properties) {
	const parsedProps = Object.keys(object)
		.filter(key => properties.indexOf(key) >= 0)
		.reduce((acc, key) => {
			acc[key] = parseInt(object[key]);
			return acc;
		}, {});

	return Object.assign({}, object, parsedProps);
}