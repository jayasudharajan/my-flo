export default class CustomerEmailSubscriptionACLStrategy {
  constructor(aclMiddleware) {
    this.retrieve = aclMiddleware.requiresPermissions([
      {
        resource: 'User',
        permission: 'retrieveCustomerEmailSubscription',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.updateSubscriptions = aclMiddleware.requiresPermissions([
      {
        resource: 'User',
        permission: 'updateCustomerEmailSubscription',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.retrieveAllEmails = (res, req, next) => next();
  }
}