import SubResourceProvider from './SubResourceProvider';
import DIFactory from  '../../../../util/DIFactory';
import ICDService from '../../icd-v1_5/ICDService';
import _ from 'lodash';

class LocationProvider extends SubResourceProvider {
  constructor(icdService, locationService) {
    super('Location');
    this.icdService = icdService;
  }

  retrieveByDeviceId({ device_id }) {
    return (
      device_id ?
        this.icdService.retrieveByDeviceId(device_id)
          .then(({ Items: [icd] }) => (icd || {}).location_id) :
        Promise.resolve()
    )
    .then(locationId => this.formatSubResource(locationId));
  }

  retrieveByICDId({ icd_id }) {
    return (
      icd_id ?
        this.icdService.retrieve(icd_id)
          .then(({ Item: icd }) => (icd || {}).location_id) :
        Promise.resolve()
    )
    .then(locationId => this.formatSubResource(locationId));
  }

  retrieveByLocationId({ location_id }) {
    return Promise.resolve(
      _.isArray(location_id) ?
        location_id.map(id => this.formatSubResource(id)) :
        this.formatSubResource(location_id)
    );
  }
}

export default new DIFactory(LocationProvider, [ICDService]);
