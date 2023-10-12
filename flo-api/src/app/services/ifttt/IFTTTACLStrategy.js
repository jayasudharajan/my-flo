
export default class IFTTTACLStrategy {
  constructor(aclMiddleware) {

    this.getStatus = (req, res, next) => next();

    this.getUserInfo = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'getUserInfo',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.testSetup = (req, res, next) => next();

    this.deleteTriggerIdentity = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'deleteTriggerIdentity',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.getCriticalAlertDetectedTriggerEvents = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'getAlertDetectedTriggerEventsBySeverity',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.getWarningAlertDetectedTriggerEvents = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'getAlertDetectedTriggerEventsBySeverity',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.getInfoAlertDetectedTriggerEvents = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'getAlertDetectedTriggerEventsBySeverity',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.openValveAction = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'deviceControlAction',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.closeValveAction = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'deviceControlAction',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.changeSystemModeAction = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'deviceControlAction',
        get: ({ token_metadata: { user_id } }) => Promise.resolve(user_id)
      }
    ]);

    this.notifyRealtimeAlert = aclMiddleware.requiresPermissions([
      {
        resource: 'IFTTT',
        permission: 'notifyRealtimeAlert'
      }
    ]);
  }
}