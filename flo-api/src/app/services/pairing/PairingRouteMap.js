export default class PairingRouteMap {
  constructor() {
    
    this.scanQRCode = [
      {
        post: '/qr'
      }
    ];

    this.retrievePairingDataByICDId = [
      {
        get: '/qr/icd/:icd_id'
      }
    ];

    this.unpairDevice = [
      {
        post: '/unpair/:icd_id'
      }
    ];

    this.initPairing = [
      {
        post: '/init'
      }
    ];

    this.completePairing = [
      {
        post: '/complete/:icd_id'
      }
    ];
  }
}