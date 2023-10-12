const unmarshalItem = require('dynamodb-marshaler').unmarshalItem;
const decrypt = require('./util/decrypt');
const PubSub = require('./pubsub');

const pubsub = new PubSub();
require('./indices')(pubsub);

exports.handler = (payload, context, done) => {
	try {

		if (process.env.PAUSED) {
			setTimeout(() => done(new Error('LAMBDA PAUSED.')), 299999);
		} else {
			const promises = payload.Records
				.map(record => handleRecord(record));

			Promise.all(promises)
				.then(() => done(null, true))
				.catch(err => {
					console.log(err);
					done(err);
				});
		}

	} catch (err) {
		console.log(err);
		done(err);
	}
} 

function handleRecord(record) {
	const item = unmarshalItem(record.dynamodb.NewImage || record.dynamodb.OldImage || {});
	const timestamp = record.dynamodb.ApproximateCreationDateTime;
	const tableName = parseTableName(record.eventSourceARN);
	const eventName = record.eventName;

	return decrypt(tableName, item)
		.then(decryptedItem => pubsub.publish(tableName, eventName, decryptedItem));
}

function parseTableName(eventSourceARN) {
	return eventSourceARN.split(':')[5].split('/')[1];
}