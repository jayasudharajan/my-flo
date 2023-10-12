import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import AuthorizationService from '../authorization/AuthorizationService';
import AccessControlTable from './AccessControlTable';
import SubResourceProviderFactory from './sub-resource-providers/SubResourceProviderFactory';
import ForbiddenException from '../utils/exceptions/ForbiddenException';
import ClientService from '../client/ClientService';
import Oauth2Service from '../oauth2/OAuth2Service';

class AccessControlService {
  constructor(authorizationService, aclTable, subResourceProviderFactory, clientService, oauth2Service) {
    this.authorizationService = authorizationService;
    this.aclTable = aclTable;
    this.subResourceProviderFactory = subResourceProviderFactory;
    this.clientService = clientService;
    this.oauth2Service = oauth2Service;
  }

  retrieveMethodResourcePermissions(methodId) {
    return this.aclTable.retrieve(methodId)
      .then(({ Item = {} }) => Item.resource_permissions || []);
  }

  authorize(tokenMetadata, methodId, params) {
    const { user_id, client_id, nonce } = tokenMetadata;

    return this.retrieveMethodResourcePermissions(methodId)
      .then(resourcePermissions => Promise.all(
        !resourcePermissions || !resourcePermissions.length ?
        [true] :
        resourcePermissions
          .map(({ resource, permission, retrieve_by }) => {
            const retrieveByMethod = retrieve_by && retrieve_by.method;
            const retrieveByMethodParamNames = retrieve_by && retrieve_by.params;
            const retrieveByMethodParams = retrieve_by && _.pick(params, retrieveByMethodParamNames);

            return this.authorizationService.validateRoles(
              resource, 
              permission, 
              user_id, 
              client_id, 
              nonce,
              retrieve_by && this.subResourceProviderFactory.getSubResourceProvider(resource, retrieveByMethod, retrieveByMethodParams, tokenMetadata)
            );
          })
      ))
      .then(areAnyAllowed => areAnyAllowed.some(isAllowed => isAllowed))
      .then(isAllowed => 
        isAllowed ? 
          tokenMetadata :
          Promise.reject(new ForbiddenException())
      )
      .then(tokenMetadata => {
        return this.authorizationService.retrieveRoles(user_id, client_id, nonce)
          .then(roles => ({
            ...tokenMetadata,
            roles
          }));
      })
  }

  refreshUserRoles(userId) {
    return Promise.all([
      // Load roles for legacy tokens
      this.authorizationService.loadUserACLRoles(userId),
      // Retrieve all active clients for user
      this.clientService.retrieveClientsByUserId(userId)
        .then(({ data: userClients }) => 
          Promise.all(
            userClients.map(userClient => 
              this.clientService.retrieve(userClient.client_id)
                .then(client => 
                  // If client has limited scopes, load those roles, otherwise load full roles
                  _.isEmpty(client.scopes) ?
                    this.authorizationService.loadUserACLRoles(userId, client.client_id) :
                    this.oauth2Service.loadClientScopeRoles(client.client_id, userId, client.scopes)
                )
            )
          )
        )
    ]);
  }
}

export default new DIFactory(AccessControlService, [AuthorizationService, AccessControlTable, SubResourceProviderFactory, ClientService, Oauth2Service]);