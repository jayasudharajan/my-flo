const _ = require('lodash');
const locationSchemas = require('../../location-v1_5/resources/tableSchemas');
const userAccountSchemas = require('../../user-account/resources/tableSchemas');
const InsuranceLetterRequestLogSchema = require('../../../../../dist/app/models/schemas/InsuranceLetterRequestLogSchema');
const AccountSchema = require('../../../../../dist/app/models/schemas/accountSchema');

module.exports = _.uniqBy(
	[
    InsuranceLetterRequestLogSchema,
    AccountSchema
	]
	.concat(locationSchemas)
	.concat(userAccountSchemas),
	'TableName'
);