
class AuthMiddlewareMock {
  requiresAuth() {
    return (req, res, next) => next();
  }
}

module.exports = AuthMiddlewareMock;
