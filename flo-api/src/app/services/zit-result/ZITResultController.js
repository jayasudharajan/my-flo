import ZITResultService from './ZITResultService';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';
import DIFactory from '../../../util/DIFactory';

class ZITResultController extends CrudController {

  constructor(zitResultService) {
    super(zitResultService.zitResultTable);

    this.zitResultService = zitResultService;
  }

  /**
   * Query set ZITResult with same hashkey.
   */
  retrieveByIcdId({ params: { icd_id } }, res, next) {
    return this.zitResultService.retrieveByIcdId(icd_id);
  }

  /**
   * Query set ZITResult GSI ZITRound with same hashkey.
   */
  retrieveByRoundId({ params: { round_id } }, res, next) {
    return this.zitResultService.retrieveByRoundId(round_id);
  }

  retrieveByDeviceId({ params: { device_id } }, res, next) {
    return this.zitResultService.retrieveByDeviceId(device_id);
  }

  createByDeviceId({ params: { device_id }, body: { test, data } }, res, next) {
    return this.zitResultService.createByDeviceId(device_id, test, data);
  }
}

export default new DIFactory(new ControllerWrapper(ZITResultController), [ZITResultService]);