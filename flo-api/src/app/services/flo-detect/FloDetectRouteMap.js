export default class FloDetectRouteMap {
  constructor() {

    this.updateFixturesWithFeedback = [
      { post: '/feedback/:device_id/:start_date/:end_date' }
    ];

    this.logFloDetect = [
      { post: '/:device_id' }
    ];

    this.retrieveByDeviceIdAndDateRange = [
      { get: '/results/:device_id/:start_date/:end_date' }
    ];

    this.retrieveByDeviceIdAndDateRangeWithStatus = [
      { get: '/computations/results/:device_id/:start_date/:end_date' }
    ];

    this.retrieveLatestByDeviceId = [
      { get: '/latest/:device_id/:duration' }
    ];   

    this.retrieveLatestByDeviceIdWithStatus = [
      { get: '/computations/latest/:device_id/:duration' }
    ];

    this.retrieveLatestByDeviceIdInDateRange = [
      { get: '/latest/:device_id/:duration/range/:start_date/:end_date' }
    ];

    this.retrieveLatestByDeviceIdInDateRangeWithStatus = [
      { get: '/computations/latest/:device_id/:duration/range/:start_date/:end_date' }
    ];

    this.updateEventChronologyWithFeedback = [
      { post: '/event/:device_id/:request_id/:start_date/feedback' }
    ];

    this.retrieveEventChronologyPage = [
      { get: '/event/:device_id/:request_id' }
    ];

    this.batchCreateEventChronology = [
      { post: '/event/:device_id/:request_id' }
    ];

    this.logFixtureAverages = [
      { post: '/averages' }
    ];

    this.retrieveLatestFixtureAverages = [
      { get: '/averages/latest/:device_id/:duration' }
    ];
  }
}