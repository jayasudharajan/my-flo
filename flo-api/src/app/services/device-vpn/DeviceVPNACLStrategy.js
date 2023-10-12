export default class DeviceVPNACLStrategy {
  constructor(aclMiddleware) {

    this.enable = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'vpn'
      }
    ]);

    this.disable = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'vpn'
      }
    ]);

    this.retrieveVPNConfig = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'vpn'
      }
    ]);
  }
}