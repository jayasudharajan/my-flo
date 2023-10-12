const _ = require('lodash');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');
const locationTableSchemas = require('../../location-v1_5/resources/tableSchemas');
const legacyAuthTableSchemas = require('../../legacy-auth/resources/tableSchemas');
const oauth2TableSchemas = require('../../oauth2/resources/tableSchemas');
const userRegistrationTokenMetadataSchema = require('../../../../../dist/app/models/schemas/UserRegistrationTokenMetadataSchema');

const schemas = [userRegistrationTokenMetadataSchema]
	.concat(userAccountTableSchemas)
	.concat(locationTableSchemas)
	.concat(oauth2TableSchemas)
	.concat(legacyAuthTableSchemas);

module.exports = _.uniqBy(schemas, 'TableName');