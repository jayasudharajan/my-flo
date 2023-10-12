import UltimaVersionService from './UltimaVersionService';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';
import DIFactory from '../../../util/DIFactory';

class UltimaVersionController extends CrudController {

  constructor(ultimaVersionService) {
    super(ultimaVersionService.ultimaVersionTable);
    this.ultimaVersionService = ultimaVersionService;
  }
  
  /**
   * Simple Table scan to retrieve multiple records.
   */
  scan(req, res, next) {
    return this.ultimaVersionService.scan();
  }

  /**
   * Query set ultimaVersion with same hashkey.
   */
  retrieveByModel({ params: { model }}, res, next) {
    return this.ultimaVersionService.retrieveByModel(model);
  }
}

export default new DIFactory(new ControllerWrapper(UltimaVersionController), [UltimaVersionService]);


