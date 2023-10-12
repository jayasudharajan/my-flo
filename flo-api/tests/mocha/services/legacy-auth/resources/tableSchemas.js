const authenticationTableSchemas = require('../../authentication/resources/tableSchemas');
const UserTokenSchema = require('../../../../../dist/app/models/schemas/userTokenSchema');

module.exports = [UserTokenSchema].concat(authenticationTableSchemas);
