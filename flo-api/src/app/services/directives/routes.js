import _ from 'lodash';
import express from 'express';
import { directiveDataMap } from './models/directiveData';
import directiveRequest from './models/directiveRequest';
import controller from './controller';
import { requiresPermissions } from '../../middleware/acl';
import reqValidate from '../../middleware/reqValidate';
import { lookupByICDId } from '../../../util/icdUtils';
import { lookupByLocationId } from '../../../util/accountGroupUtils';

class DirectiveRouter {
  constructor(authMiddleware) {
    const getLocationByICDId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => location_id);
    const getGroupIdByICDId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));
    const router = express.Router();
    this.router = router;

    _.keys(directiveDataMap)
      .forEach(directive => {
        const endpoint = directive.split('-').join('');

        router.route(`/icd/:icd_id/${ endpoint }`)
          .post(
            authMiddleware.requiresAuth({ addUserId: true }),
            reqValidate(directiveRequest[directive]),
            requiresPermissions([
              {
                resource: 'Location',
                permission: directive,
                get: getLocationByICDId
              },
              {
                resource: 'AccountGroup',
                permission: directive,
                get: getGroupIdByICDId
              },
              {
                resource: 'Directives',
                permission: directive
              }
            ]),
            controller[directive]
          );
      });

    router.route('/history/:directive_id')
      .get(
        authMiddleware.requiresAuth({ addUserId: true }),
        reqValidate(directiveRequest.retrieveDirectiveLogByDirectiveId),
        requiresPermissions([
          {
            resource: 'Directives',
            permission: 'retrieveDirectiveLogByDirectiveId'
          }
        ]),
        controller.retrieveDirectiveLogByDirectiveId
      );
	}

  routes() {
    return this.router;
  }
}

export default DirectiveRouter;