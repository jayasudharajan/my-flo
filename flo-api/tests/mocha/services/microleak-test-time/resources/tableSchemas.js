const _ = require('lodash');
const locationSchemas = require('../../location-v1_5/resources/tableSchemas');
const ICDSchema = require('../../../../../dist/app/models/schemas/icdSchema');
const MicroLeakTestTimeSchema = require('../../../../../dist/app/models/schemas/MicroLeakTestTimeSchema');
const DirectiveLogSchema = require('../../../../../dist/app/models/schemas/directiveLogSchema');

module.exports = _.uniqBy(
	[
    MicroLeakTestTimeSchema,
    ICDSchema,
    DirectiveLogSchema
	]
	.concat(locationSchemas),
	'TableName'
);