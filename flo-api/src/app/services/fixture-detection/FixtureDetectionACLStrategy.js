import NotFoundException from '../utils/exceptions/NotFoundException';

export default class FixtureDetectionACLStrategy {
  constructor(aclMiddleware, icdService) {

    function getLocationIdByDeviceId(deviceId) {
      return icdService.retrieveByDeviceId(deviceId).then(({ Items }) => {
        if (Items.length < 1) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }
        return Items[0].location_id;
      })
    }

    this.logFixtureDetection = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'logFixtureDetection'
      }
    ]);


    this.retrieveFixtureDetectionResults = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveFixtureDetectionResults',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.retrieveByDeviceIdAndDateRange = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveByDeviceIdAndDateRange',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.retrieveLatestByDeviceId = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveLatestByDeviceId',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.runFixturesDetection = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'runFixturesDetection',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.updateFixturesWithFeedback = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'updateFixturesWithFeedback',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);
  }
}