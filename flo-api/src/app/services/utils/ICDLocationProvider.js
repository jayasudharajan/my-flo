
export default class ICDLocationProvider {
  constructor(icdService) {
    this.icdService = icdService;
  }

  getLocationIdByICDId({ params: { icd_id } }) {
    return this.icdService.retrieve(icd_id)
      .then(({ Item }) => {
        
        if (!Item) {
          return null;
        }

        return Item.location_id;
      });
  }

  getLocationIdByDeviceId({ params: { device_id } }) {
    return this.icdService.retrieveByDeviceId(device_id)
      .then(({ Items }) => {

        if (!Items.length) {
          return null;
        }

        return Items[0].location_id;
      });
  }

  getLocationIdByDeviceIdBody({ body: { device_id } }) {
    return this.icdService.retrieveByDeviceId(device_id)
      .then(({ Items }) => {

        if (!Items.length) {
          return null;
        }

        return Items[0].location_id;
      });
  }
}