export default class FixtureDetectionRouteMap {
  constructor() {

    this.updateFixturesWithFeedback = [
      { post: '/feedback/:device_id/:request_id/:created_at' }
    ];

    this.logFixtureDetection = [
      { post: '/:device_id' }
    ];

    this.retrieveFixtureDetectionResults = [
      { get: '/results/:device_id/:request_id' }
    ];

    this.retrieveByDeviceIdAndDateRange = [
      { get: '/results/:device_id/:start_date/:end_date' }
    ];

    this.retrieveLatestByDeviceId = [
      { get: '/latest/:device_id' }
    ];

    this.runFixturesDetection = [
      { post: '/run/:device_id' }
    ];

    
  }
}