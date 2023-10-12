import DirectiveResponseService from './DirectiveResponseService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class DirectiveResponseController extends CrudController {

  constructor(directiveResponseService) {
    super(directiveResponseService.directiveResponseTable);
    this.directiveResponseService = directiveResponseService;
  }

  logDirectiveResponse({ params: { device_id }, body }, res, next) {
    return this.directiveResponseService.logDirectiveResponse(device_id, body);
  }
}

export default new DIFactory(new ControllerWrapper(DirectiveResponseController), [ DirectiveResponseService ]);