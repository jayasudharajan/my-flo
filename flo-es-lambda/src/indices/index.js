const indices = [
	require('./users'),
	require('./alarmnotificationdeliveryfilterlogs'),
	require('./icdalarmincidentregistries'),
	require('./icdalarmincidentregistrylogs'),
	require('./icds'),
	require('./alerts'),
	require('./stockicdlogs'),
  require('./activity-log')
];

module.exports = pubsub => indices.forEach(index => index(pubsub));