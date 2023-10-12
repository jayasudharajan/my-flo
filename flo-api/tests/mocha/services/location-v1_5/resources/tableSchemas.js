const _ = require('lodash');
const locationTableSchema = require('../../../../../dist/app/models/schemas/locationSchema');
const authorizationTableSchemas = require('../../authorization/resources/tableSchemas');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');

module.exports = _.uniqBy(
	[locationTableSchema]
		.concat(authorizationTableSchemas)
		.concat(userAccountTableSchemas),
	({ TableName }) => TableName
);