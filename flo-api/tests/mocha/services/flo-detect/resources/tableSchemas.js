const _ = require('lodash');
const ICDSchema = require('../../../../../dist/app/models/schemas/icdSchema');
const FloDetectResultSchema = require('../../../../../dist/app/models/schemas/FloDetectResultSchema');
const FloDetectEventChronologySchema = require('../../../../../dist/app/models/schemas/FloDetectEventChronologySchema');
const FloDetectFixtureAverageSchema =  require('../../../../../dist/app/models/schemas/FloDetectFixtureAverageSchema');
const onboardingTableSchemas = require('../../onboarding/resources/tableSchemas');

module.exports = _.uniqBy(
  [
    ICDSchema,
    FloDetectResultSchema,
    FloDetectEventChronologySchema,
    FloDetectFixtureAverageSchema
  ]
  .concat(onboardingTableSchemas),
  'TableName'
);