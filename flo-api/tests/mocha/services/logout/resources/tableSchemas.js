const _ = require('lodash');
const oauth2TableSchemas = require('../../oauth2/resources/tableSchemas');
const pushNotificationTokenTableSchemas = require('../../push-notification-token/resources/tableSchemas');
const clientTableSchemas = require('../../client/resources/tableSchemas');

module.exports = _.uniqBy(
  oauth2TableSchemas
    .concat(pushNotificationTokenTableSchemas)
    .concat(clientTableSchemas),
  'TableName'
);