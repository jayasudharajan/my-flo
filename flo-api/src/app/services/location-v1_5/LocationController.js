import LocationService from './LocationService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class LocationController extends CrudController {

  constructor(locationService) {
    super(locationService.locationTable);
    this.locationService = locationService;
  }

  retrieveByLocationId({ params: { location_id } }) {
  	return this.locationService.retrieveByLocationId(location_id);
  }

  retrieveByAccountId({ params: { account_id } }) {
  	return this.locationService.retrieveByAccountId(account_id);
  }

  createByAccountId({ params: { account_id }, body }) {
  	return this.locationService.createInAccount({ ...body, account_id });
  } 
}

export default new DIFactory(new ControllerWrapper(LocationController), [ LocationService ]);
