
class ACLMiddleware {
  checkPermissions(resource) {
    return (permission, getSubResource) => {
      return (req, res, next) => {
        return next();
      }
    }
  }

  requiresPermissions(resourcePermissions) {
    return (req, res, next) => {
      return next();
    }
  }
}

module.exports = ACLMiddleware;