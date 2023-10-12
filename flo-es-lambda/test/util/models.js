const uuid = require('uuid');
const moment = require('moment');

exports.createUser = createUser;
exports.createUserDetail = createUserDetail;
exports.createLocation = createLocation;
exports.createAccount = createAccount;
exports.createICD = createICD;
exports.createAlarmNotificationDeliveryFilter = createAlarmNotificationDeliveryFilter;
exports.createICDAlarmIncidentRegistry = createICDAlarmIncidentRegistry;
exports.createICDAlarmIncidentRegistryLog = createICDAlarmIncidentRegistryLog;
exports.createICDAlarmNotificationDeliveryRule = createICDAlarmNotificationDeliveryRule;
exports.createUserAlarmNotificationDeliveryRule = createUserAlarmNotificationDeliveryRule;

function createUser() {
	return {
		id: uuid.v4(),
		email: 'test@flotechnologies.com',
		is_active: true,
		is_system_user: false
	};
}

function createUserDetail() {
	return { 
		user_id: uuid.v4(),
		firstname: 'Foo',
		middlename: 'Bar',
		lastname: 'Baz',
		phone_mobile: '1112223333'
	};
}

function createLocation() {
	return {
		location_id: uuid.v4(),
		account_id: uuid.v4(),
		country: 'USA',
		state: 'CA',
		city: 'Los Angeles',
		postalcode: '90017',
		timezone: 'America/Los_Angeles'
	};
}

function createAccount() {
	return {
		id: uuid.v4(),
		group_id: uuid.v4(),
		owner_user_id: uuid.v4()
	};
}

function createICD() {
	return {
		id: uuid.v4(),
		location_id: uuid.v4(),
		device_id: uuid.v4(),
		is_paired: true
	};
}

function createAlarmNotificationDeliveryFilter(timestamp) {
	const time = moment(timestamp || undefined);

	return {
		alarm_id: 15,
		alarm_id_system_mode: '15_3',
		created_at: time.toISOString(),
		expires_at: moment(time).add(1, 'hours').toISOString(),
		icd_id: uuid.v4(),
		incident_time: time.toISOString(),
		last_decision_user_id: uuid.v4(),
		last_icd_alarm_incident_registry_id: uuid.v4(),
		severity: 2,
		status: 1,
		system_mode: 3,
		updated_at: time.toISOString(),
	};
}

function createICDAlarmIncidentRegistry(_timestamp) {
	const timestamp = moment(_timestamp || undefined).toISOString();	
	const user_id = uuid.v4();
	const location_id = uuid.v4();

	return {
	  account_id: uuid.v4(),
	  acknowledged_by_user: 1,
	  alarm_id: 15,
	  alarm_name: 'PRESSURE MINIMUM',
	  created_at: timestamp,
	  friendly_name: 'LOW PRESSURE',
	  icd_data: {
	    device_id: '8cc7aa0277c0',
	    id: '96ef35e9-7575-494d-845d-b811c23e03ed',
	    local_time: '21:59:36',
	    location_id: location_id,
	    system_mode: 3,
	    timezone: 'US/Pacific',
	    zone_mode: 1
	  },
	  icd_id: uuid.v4(),
	  id: uuid.v4(),
	  incident_time: timestamp,
	  location_id: location_id,
	  self_resolved: 0,
	  self_resolved_message: null,
	  severity: 2,
	  telemetry_data: {
	    f: 0,
	    fd: 3,
	    fdl: 50,
	    ft: 0,
	    ftl: 8,
	    m: 0,
	    mafr: 8,
	    o: 0,
	    p: 0.5,
	    pef: 0,
	    pefl: 50,
	    pmax: 80,
	    pmin: 20,
	    sw1: 1,
	    sw2: 0,
	    t: 90,
	    tmax: 150,
	    tmin: 40,
	    wf: 0
	  },
	  user_action_taken: {
	    action_id: 12,
	    user_id: user_id
	  },
	  users: [
	    {
	      delivery_preferences: [
	        3,
	        4
	      ],
	      user_id: user_id
	    }
	  ]
	}
}

function createICDAlarmIncidentRegistryLog(_timestamp) {
	const timestamp = moment(_timestamp || undefined).toISOString();	

	return {
		created_at: timestamp,
		delivery_medium: 2,
		delivery_medium_status: 22,
		icd_alarm_incident_registry_id: uuid.v4(),
		id: uuid.v4(),
		receipt_id: uuid.v4(),
		status: 2,
		unique_id: uuid.v4(),
		user_id: uuid.v4()
	};
}

function createICDAlarmNotificationDeliveryRule() {
	return {
	  alarm_id: 15,
	  essential: false,
	  extra_info: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	  filter_settings: {
	    exempted: false,
	    max_delivery_amount: 1,
	    max_delivery_amount_scope: 1,
	    max_minutes_elapsed_since_incident_time: 60,
	    send_when_valve_is_closed: false
	  },
	  friendly_description: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	  friendly_name: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	  graveyard_time: {
	    enabled: true,
	    ends_time_in_24_format: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	    'send_app-notification': false,
	    send_email: true,
	    send_sms: false,
	    start_time_in_24_format: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.'
	  },
	  has_action: false,
	  internal_id: 1029,
	  mandatory: [
	    3,
	    4
	  ],
	  name: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	  optional: [
	    3,
	    4
	  ],
	  severity: 2,
	  system_mode: 3,
	  user_actions: {
	    actions: [
	      {
	        display: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        display_when: {
	          alarm_notification_delivery_filter: {
	            status: 3
	          },
	          chains: {},
	          time: {},
	          valve: {}
	        },
	        id: 1,
	        option: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        sort: 1
	      },
	      {
	        display: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        display_when: {
	          alarm_notification_delivery_filter: {
	            status: 3
	          },
	          chains: {},
	          time: {},
	          valve: {}
	        },
	        id: 6,
	        option: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        sort: 2
	      },
	      {
	        display: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        display_when: {
	          alarm_notification_delivery_filter: {
	            status: 3
	          },
	          chains: {},
	          time: {},
	          valve: {}
	        },
	        id: 3,
	        option: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        sort: 3
	      },
	      {
	        display: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        display_when: {
	          alarm_notification_delivery_filter: {
	            status: 3
	          },
	          chains: {},
	          time: {},
	          valve: {
	            state: 0
	          }
	        },
	        id: 5,
	        option: 'If your Flo valve is closed, open your Flo valve then open a fixture to see if normal flow is present.  If flow rate is noticeable low, then please inspect any water filtration systems (if present) to verify filter are not at end of life. If problem still persists then please contact your plumber to further troubleshoot this issue.  If you have any questions, please contact Flo Support.',
	        sort: 4
	      },
	      {
	        display: 'Turn Valve Off',
	        display_when: {
	          alarm_notification_delivery_filter: {
	            status: 3
	          },
	          chains: {},
	          time: {},
	          valve: {
	            state: 1
	          }
	        },
	        id: 7,
	        option: 'Turn Valve Off',
	        sort: 5
	      }
	    ],
	    timeout: 300
	  }
	};
}

function createUserAlarmNotificationDeliveryRule(_location_id, _alarm_id, _system_mode) {
	const location_id = _location_id || uuid.v4();
	const alarm_id = _alarm_id || 15;
	const system_mode = _system_mode || 3;

	return {
	    user_id: uuid.v4(),
	    location_id,
	    location_id_alarm_id_system_mode: `${ location_id }_${ alarm_id }_${ system_mode }`,
	    alarm_id,
	    system_mode,
	    essential: true,
	    severity: 1,
	    mandatory: [2, 3],
	    optional: [2],
	    filter_settings: {
	        exempted: false,
	        max_delivery_amount: 1,
	        max_delivery_amount_scope: 1,
	        max_minutes_elapsed_since_incident_time: 60,
	        send_when_valve_is_closed: false
	    },
	    graveyard_time: {
	        enabled: true,
	        ends_time_in_24_format: '07:00',
	        'send_app-notification': false,
	        send_email: true,
	        send_sms: false,
	        start_time_in_24_format: '00:00'
	    },
	    internal_id: 1028
	}
}