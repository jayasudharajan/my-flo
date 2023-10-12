const authorizationTableSchemas = require('../../authorization/resources/tableSchemas');
const UserSchema = require('../../../../../dist/app/models/schemas/userSchema');
const UserDetailSchema = require('../../../../../dist/app/models/schemas/userDetailSchema');
const AccountSchema = require('../../../../../dist/app/models/schemas/accountSchema');
const LocationSchema = require('../../../../../dist/app/models/schemas/locationSchema');

module.exports = [
	UserSchema,
	UserDetailSchema,
	AccountSchema,
	LocationSchema
].concat(authorizationTableSchemas);