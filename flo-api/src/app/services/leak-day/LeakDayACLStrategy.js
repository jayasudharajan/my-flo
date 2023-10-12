export default class LeakDayACLStrategy {
  constructor(aclMiddleware) {

    this.retrieveLeakDayCountsByDevice = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'retrieveAll'
    }]);

    this.retrieveDeviceLeakDayCountTotals = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'retrieveAll'
    }]);
  }
}