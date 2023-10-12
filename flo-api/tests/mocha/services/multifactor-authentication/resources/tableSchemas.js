const _ = require('lodash');
const UserMultifactorAuthenticationSettingSchema = require('../../../../../dist/app/models/schemas/UserMultifactorAuthenticationSettingSchema');
const MultifactorAuthenticationTokenMetadataSchema = require('../../../../../dist/app/models/schemas/MultifactorAuthenticationTokenMetadataSchema');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');

module.exports = _.uniqBy(
	[
    UserMultifactorAuthenticationSettingSchema,
    MultifactorAuthenticationTokenMetadataSchema
	]
	.concat(userAccountTableSchemas),
	'TableName'
);