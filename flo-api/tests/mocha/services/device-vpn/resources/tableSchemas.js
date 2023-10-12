const VPNWhitelistSchema = require('../../../../../dist/app/models/schemas/VPNWhitelistSchema');
const taskSchedulerSchemas = require('../../task-scheduler/resources/tableSchemas');
const directivesSchemas = require('../../directives/resources/tableSchemas');
const icdTableSchemas = require('../../icd-v1_5/resources/tableSchemas');

module.exports = [ VPNWhitelistSchema	].concat(icdTableSchemas).concat(taskSchedulerSchemas).concat(directivesSchemas);