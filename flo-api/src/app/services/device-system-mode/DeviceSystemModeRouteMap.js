
export default class DeviceSystemModeRouteMap {
  constructor() {
    this.setSystemMode = [
      {
        post: '/icd/:icd_id/setsystemmode'
      }
    ];
    this.enableForcedSleep = [
      {
        post: '/icd/:icd_id/forcedsleep/enable'
      }
    ];
    this.disableForcedSleep = [
      {
        post: '/icd/:icd_id/forcedsleep/disable'
      }
    ];
    this.sleep = [
      {
        post: '/icd/:icd_id/sleep'
      }
    ];
  }
}