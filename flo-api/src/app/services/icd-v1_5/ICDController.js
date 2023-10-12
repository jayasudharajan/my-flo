import ICDService from './ICDService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class ICDController extends CrudController {

  constructor(icdService) {
    super(icdService.icdTable);
    this.icdService = icdService;
  }

  retrieveByLocationId({ params: { location_id } }) {
  	return this.icdService.retrieveByLocationId(location_id);
  }

  retrieveByDeviceId({ params: { device_id } }) {
    return this.icdService.retrieveByDeviceId(device_id);
  }

}

export default new DIFactory(new ControllerWrapper(ICDController), [ ICDService ]);