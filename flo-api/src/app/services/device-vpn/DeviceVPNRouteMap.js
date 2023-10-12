export default class DeviceVPNRouteMap {
  constructor() {

    this.enable = [
      { post: '/:device_id/enable' }
    ];

    this.disable = [
      { post: '/:device_id/disable' }
    ];

    this.retrieveVPNConfig = [
      { get: '/:device_id/config' }
    ];
  }
}