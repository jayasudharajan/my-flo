const _ = require('lodash');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');
const clientTableSchemas = require('../../client/resources/tableSchemas');
const UserLockStatusSchema = require('../../../../../dist/app/models/schemas/UserLockStatusSchema');
const UserLoginAttemptSchema = require('../../../../../dist/app/models/schemas/UserLoginAttemptSchema');
const multifactorAuthenticationSchemas = require('../../multifactor-authentication/resources/tableSchemas');

module.exports = _.uniqBy(
	[UserLockStatusSchema, UserLoginAttemptSchema]
		.concat(userAccountTableSchemas)
		.concat(clientTableSchemas)
		.concat(multifactorAuthenticationSchemas),
	({ TableName }) => TableName
);

