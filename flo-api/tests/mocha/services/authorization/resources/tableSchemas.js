const UserAccountRoleSchema = require('../../../../../dist/app/models/schemas/userAccountRoleSchema');
const UserLocationRoleSchema = require('../../../../../dist/app/models/schemas/userLocationRoleSchema');
const UserAccountGroupRoleSchema = require('../../../../../dist/app/models/schemas/UserAccountGroupRoleSchema');
const UserSystemRoleSchema = require('../../../../../dist/app/models/schemas/UserSystemRoleSchema');
const systemUserTableSchemas = require('../../system-user/resources/tableSchemas');

module.exports = [
	UserAccountRoleSchema,
	UserLocationRoleSchema,
	UserAccountGroupRoleSchema,
	UserSystemRoleSchema
]
.concat(systemUserTableSchemas);