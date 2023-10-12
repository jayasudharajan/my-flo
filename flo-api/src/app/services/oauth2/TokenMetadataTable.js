import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import moment from 'moment';

export default class TokenMetadataTable extends DynamoTable {
	constructor(tableName, dynamoDbClient) {
		super(tableName, 'token_id', undefined, dynamoDbClient);
	}

	marshal(data) {
		return super.marshal(
			data.expires_at ? { ...data, _expires_at_secs: moment(data.expires_at).unix() } : data
		);
	}

	marshalPatch(keys, data) {
		return super.marshalPatch(
			keys,
			data.expires_at ? { ...data, _expires_at_secs: moment(data.expires_at).unix() } : data
		);
	}
}