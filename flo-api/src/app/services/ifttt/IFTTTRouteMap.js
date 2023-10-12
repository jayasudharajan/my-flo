export default class IFTTTRouteMap {
  constructor() {
    this.getStatus = [
      { get: '/status' }
    ];

    this.getUserInfo = [
      { get: '/user/info' }
    ];

    this.testSetup = [
      { post: '/test/setup' }
    ];

    //This seems to be not working in dev
    this.deleteTriggerIdentity = [
      { 'delete': '/triggers/:trigger_slug/trigger_identity/:trigger_identity' }
    ];

    this.getCriticalAlertDetectedTriggerEvents = [
      { post: '/triggers/critical_alert_detected' }
    ];

    this.getWarningAlertDetectedTriggerEvents = [
      { post: '/triggers/warning_alert_detected' }
    ];

    this.getInfoAlertDetectedTriggerEvents = [
      { post: '/triggers/info_alert_detected' }
    ];

    this.openValveAction = [
      { post: '/actions/turn_water_on' }
    ];

    this.closeValveAction = [
      { post: '/actions/turn_water_off' }
    ];

    this.changeSystemModeAction = [
      { post: '/actions/change_device_mode' }
    ];

    this.notifyRealtimeAlert = [
      { post: '/notifications/alert' }
    ];
  }
}