const _ = require('lodash');
const pairingPermissionSchema = require('../../../../../dist/app/models/schemas/PairingPermissionSchema');
const icdTableSchemas = require('../../icd-v1_5/resources/tableSchemas');
const stockICDTableSchemas = require('../../stock-icd/resources/tableSchemas');
const authorizationTableSchemas = require('../../authorization/resources/tableSchemas');

module.exports = _.uniqBy(
  [pairingPermissionSchema]
    .concat(icdTableSchemas)
    .concat(stockICDTableSchemas)
    .concat(authorizationTableSchemas),
  'TableName'
);