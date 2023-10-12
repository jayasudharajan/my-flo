import NotFoundException from '../utils/exceptions/NotFoundException';

export default class FloDetectACLStrategy {
  constructor(aclMiddleware, icdService) {

    function getLocationIdByDeviceId(deviceId) {
      return icdService.retrieveByDeviceId(deviceId).then(({ Items }) => {
        if (Items.length < 1) {
          return null;
        }
        return Items[0].location_id;
      })
    }

    this.logFloDetect = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'logFixtureDetection'
      }
    ]);

    this.retrieveByDeviceIdAndDateRange = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveByDeviceIdAndDateRange',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.retrieveByDeviceIdAndDateRangeWithStatus = aclMiddleware.requiresPermissions([
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


    this.retrieveLatestByDeviceIdWithStatus = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveLatestByDeviceId',
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

    this.retrieveLatestByDeviceIdInDateRange = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveByDeviceIdAndDateRange',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.retrieveLatestByDeviceIdInDateRangeWithStatus = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveByDeviceIdAndDateRange',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.updateEventChronologyWithFeedback = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'updateFixturesWithFeedback',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }     
    ]);

    this.retrieveEventChronologyPage = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveLatestByDeviceId',
        get: ({ params: { device_id } }) => getLocationIdByDeviceId(device_id)
      }
    ]);

    this.batchCreateEventChronology = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'logFixtureDetection'
      }
    ]);

    this.logFixtureAverages = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'logFixtureAverages'
      }
    ]);

    this.retrieveLatestFixtureAverages = aclMiddleware.requiresPermissions([
      {
        resource: 'ICD',
        permission: 'retrieveLatestFixtureAverages'
      }
    ]);
  }
}