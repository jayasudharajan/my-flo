
export default class FirebaseTokenACLStrategy {
  constructor(aclMiddleware) {

    this.issueToken = aclMiddleware.requiresPermissions([
      {
        resource: 'FirebaseToken',
        permission: 'issueToken'
      }
    ]);
  }
}