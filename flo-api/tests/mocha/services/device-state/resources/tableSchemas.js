const _ = require('lodash');
const icdSchemas = require('../../icd-v1_5/resources/tableSchemas');
const locationSchemas = require('../../location-v1_5/resources/tableSchemas');
const DeviceStateLogSchema = require('../../../../../dist/app/models/schemas/DeviceStateLogSchema');
const AccountSchema = require('../../../../../dist/app/models/schemas/accountSchema');

module.exports = _.uniqBy(
	[
    DeviceStateLogSchema,
    AccountSchema
  ]
  .concat(icdSchemas)
	.concat(locationSchemas),
	'TableName'
);