
export default class DeviceSystemModeACLStrategy {
  constructor(aclMiddleware, icdLocationProvider) {

    this.setSystemMode = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'setSystemMode',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ])
    this.disableForcedSleep = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'disableForcedSleep'
      },
      {
        resource: 'Location',
        permission: 'sleepSetSystemMode',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);
    this.enableForcedSleep = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'enableForcedSleep'
      },
      {
        resource: 'Location',
        permission: 'sleepSetSystemMode',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);
    this.sleep = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'sleepSetSystemMode',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);
  }  
}