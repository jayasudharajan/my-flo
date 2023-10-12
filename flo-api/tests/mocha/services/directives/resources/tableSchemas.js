const directiveLogSchema = require('../../../../../dist/app/models/schemas/directiveLogSchema');
const icdTableSchemas = require('../../icd-v1_5/resources/tableSchemas');

module.exports = [directiveLogSchema].concat(icdTableSchemas);