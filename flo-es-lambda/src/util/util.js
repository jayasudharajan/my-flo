const moment = require('moment');
const config = require('../config');

exports.getTableName = function (tableName) {
	return config.env + '_' + tableName;
}

exports.EVENTS = {
	INSERT: 'INSERT',
	MODIFY: 'MODIFY',
	REMOVE: 'REMOVE'
};

exports.createGeoLocation = function (location) {
	return Object.assign(
		{
			address2: null,
			postal_code: location.postalcode || null,
			state_or_province: location.state || null
		},
		pick(location, [
			'location_id',
			'country',
			'timezone',
			'address',
			'address2',
			'city'
		])
	);
};

exports.createAccount = function (account, subscription) {
	return Object.assign(
		{
			account_id: account.id,
			group_id: account.group_id || null
		},
		!subscription ? {} : {
			subscription: createSubscription(subscription)
		}
	);
};

function createSubscription (subscription) {
	return omit(subscription, ['account_id']);
}

exports.createSubscription = createSubscription;
exports.getLogIndexName = getLogIndexName;
exports.pick = pick;
exports.omit = omit;
exports.generateIndexNames = generateIndexNames;

function getLogIndexName(indexName, timestamp) {
	const suffix = moment.utc(timestamp || undefined).format('YYYY-MM');

	return `${indexName}-${suffix}`;
};

function pick(object, properties) {
	const pickProps = properties
		.map(prop => isObject(prop) ? Object.keys(prop)[0] : prop);
	const remapProps = properties
		.filter(prop => isObject(prop))
		.reduce((acc, prop) => Object.assign(acc, prop), {});

	return Object.keys(object)
		.filter(key => pickProps.indexOf(key) >= 0)
		.reduce((acc, key) => {
			const remappedKey = remapProps[key] || key;
			acc[remappedKey] = object[key];
			return acc;
		}, {});
}

function omit(object, properties) {
	return Object.keys(object)
		.filter(key => properties.indexOf(key) < 0)
		.reduce((acc, key) => {
			acc[key] = object[key];
			return acc;
		}, {});
}

function isObject(data) {
	return data !== null && typeof data === 'object';
}

function generateIndexNames(fromDate, toDate, indexName) {
    const numMonths = moment(toDate).startOf('month').diff(moment(fromDate).startOf('month'), 'months') + 1;

    return new Array(numMonths).fill(null)
        .map((emptyData, i) => moment(fromDate).add(i, 'months'))
        .map(date => getLogIndexName(indexName, date));
}

function defer() {
	const deferred = {};

	deferred.promise = new Promise((resolve, reject) => {
		deferred.resolve = resolve;
		deferred.reject = reject;
	});

	return deferred;
}

Promise.defer = defer;