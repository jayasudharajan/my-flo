const _ = require('lodash');
const ICDSchema = require('../../../../../dist/app/models/schemas/icdSchema');
const FixtureDetectionLogSchema = require('../../../../../dist/app/models/schemas/FixtureDetectionLogSchema');

module.exports = _.uniqBy(
	[
    ICDSchema,
    FixtureDetectionLogSchema
	],
	'TableName'
);