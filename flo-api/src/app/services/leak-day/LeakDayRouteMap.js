export default class FloDetectRouteMap {
  constructor() {

    this.retrieveLeakDayCountsByDevice = [
      { post: '/devices' }
    ];

    this.retrieveDeviceLeakDayCountTotals = [
      { post: '/totals' }
    ];
  }
}