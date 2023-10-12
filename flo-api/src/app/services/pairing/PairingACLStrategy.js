
export default class PairingACLStrategy {
  constructor(aclMiddleware, icdLocationProvider) {

    this.scanQRCode = aclMiddleware.requiresPermissions([
      {
        resource: 'StockICD',
        permission: 'retrieveByQrCode',
      }
    ]);

    this.retrievePairingDataByICDId = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrievePairingData',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);

    this.unpairDevice = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'unpairDevice',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);

    this.initPairing = aclMiddleware.requiresPermissions([
      {
        resource: 'StockICD',
        permission: 'retrieveByQrCode',
      }
    ])

    this.completePairing = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'pairDevice_v2',
        get: (...args) => icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);
  }  
}