const _ = require('lodash');
const userAccountTableSchemas = require('../../user-account/resources/tableSchemas');
const authenticationTableSchemas = require('../../authentication/resources/tableSchemas');
const authorizationTableSchemas = require('../../authorization/resources/tableSchemas');
const clientTableSchemas = require('../../client/resources/tableSchemas');
const AccessTokenMetadataSchema = require('../../../../../dist/app/models/schemas/AccessTokenMetadataSchema');
const RefreshTokenMetadataSchema = require('../../../../../dist/app/models/schemas/RefreshTokenMetadataSchema');
const AuthorizationCodeMetadataSchema = require('../../../../../dist/app/models/schemas/AuthorizationCodeMetadataSchema');
const ScopeSchema = require('../../../../../dist/app/models/schemas/ScopeSchema');

const schemas = [
	AccessTokenMetadataSchema, 
	RefreshTokenMetadataSchema,
	AuthorizationCodeMetadataSchema,
	ScopeSchema
]
.concat(userAccountTableSchemas)
.concat(authenticationTableSchemas)
.concat(authorizationTableSchemas)
.concat(clientTableSchemas);

module.exports = _.uniqBy(schemas, 'TableName');

