export default class GoogleSmartHomeACLStrategy {
  constructor(aclMiddleware) {
    this.processIntentRequest = aclMiddleware.requiresPermissions([
      {
        resource: 'GoogleSmartHome',
        permission: 'invokeWebhook',
        get: ({token_metadata: {user_id}}) => Promise.resolve(user_id)
      }
    ]);
  }
}