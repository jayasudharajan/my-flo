const _ = require('lodash');
const icdTableSchemas = require('../../icd-v1_5/resources/tableSchemas');
const directiveTableSchemas = require('../../directives/resources/tableSchemas');
const taskSchedulerTableSchemas = require('../../task-scheduler/resources/tableSchemas');
const icdForcedSystemModeSchema = require('../../../../../dist/app/models/schemas/ICDForcedSystemModeSchema');
const logoutTableSchemas = require('../../logout/resources/tableSchemas');

module.exports = _.uniqBy(
  [icdForcedSystemModeSchema]
    .concat(icdTableSchemas)
    .concat(directiveTableSchemas)
    .concat(taskSchedulerTableSchemas)
    .concat(logoutTableSchemas),
  'TableName'
);