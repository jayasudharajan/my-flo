import _ from 'lodash';
import DynamoTable from './DynamoTable';


export default class LogDynamoTable extends DynamoTable {

	constructor(tableName, keyName, rangeName, dynamoDbClient) {

		if (!rangeName) {
			throw "Range key required.";
		}

		super(tableName, keyName, rangeName, dynamoDbClient);
	}

	createLatest(data) {
		const timestampedData = _.extend(
			{ [this.rangeName]: new Date().toISOString() },
			data
		);

		return this.create(timestampedData);
	}
	
	retrieveLatest(keys, numEntries) {
		const params = {
		  TableName: this.tableName,
		  KeyConditionExpression: this.keyName + ' = :hash_key',
		  ExpressionAttributeValues: {
		    ':hash_key': _.isObject(keys) ? keys[this.keyName] : keys
		  },
		  ScanIndexForward: false,
		  Limit: numEntries || 1
		};

		return this.dynamoDbClient.query(params).promise();
	}

	retrieveBefore(keys, { end, limit, descending}) {
		return this.retrieveBetween(keys, { end, limit, descending });
	}

	retrieveAfter(keys, { start, limit, descending }) {
		return this.retrieveBetween(keys, { start, limit, descending });
	}

	retrieveBetween(keys, { start, end, limit, descending }) {
	    const params = {
	      TableName: this.tableName,
	      KeyConditionExpression: `${ this.keyName } = :hash_key AND ${ this.rangeName } BETWEEN :start AND :end`,
	      ExpressionAttributeValues: {
	        ':hash_key': keys[this.keyName],
	        ':start': start || new Date(0).toISOString(),
	        ':end': end || new Date().toISOString()
	      },
	      Limit: limit,
	      ScanIndexForward: !descending
	    };

	    return this.dynamoDbClient.query(params).promise();
	}
}