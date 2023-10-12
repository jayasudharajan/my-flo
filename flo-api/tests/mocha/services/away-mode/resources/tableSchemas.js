const _ = require('lodash');
const directivesTableSchemas = require('../../directives/resources/tableSchemas');
const icdTableSchemas = require('../../icd-v1_5/resources/tableSchemas');
const awayModeStateLogSchema = require('../../../../../dist/app/models/schemas/AwayModeStateLogSchema');

module.exports = _.uniqBy(
  [awayModeStateLogSchema]
    .concat(directivesTableSchemas)
    .concat(icdTableSchemas),
  'TableName'
);