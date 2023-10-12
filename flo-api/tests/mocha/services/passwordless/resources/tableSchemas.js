const _ = require('lodash');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');
const oauth2TableSchemas = require('../../oauth2/resources/tableSchemas');
const authorizationTableSchemas = require('../../authorization/resources/tableSchemas');
const passwordlessClientSchema = require('../../../../../dist/app/models/schemas/PasswordlessClientSchema');

module.exports = _.uniqBy(
	[passwordlessClientSchema]
	.concat(userAccountTableSchemas)
	.concat(oauth2TableSchemas)
	.concat(authorizationTableSchemas),
	'TableName'
);