import { checkPermissions, requiresPermissions }  from '../../middleware/acl';

class ACLMiddleware {
  checkPermissions(resource) {
    return checkPermissions(resource);
  }

  requiresPermissions(resourcePermissions) {
    return requiresPermissions(resourcePermissions);
  }
}

export default ACLMiddleware;