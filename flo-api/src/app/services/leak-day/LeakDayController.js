import LeakDayService from './LeakDayService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class LeakDayController {
  constructor(leakDayService) {
    this.leakDayService = leakDayService;
  }

  retrieveLeakDayCountsByDevice({ query: { size, page, leak_order }, body: { date_range, leak_status, is_subscribed }}) {
    return this.leakDayService.retrieveLeakDayCountsByDevice(
      date_range,
      { leak_status, is_subscribed },
      size || size == 0 ? parseInt(size) : undefined,
      page ? parseInt(page) : undefined,
      leak_order
    );
  }

  retrieveDeviceLeakDayCountTotals({ body: { date_range, leak_status, is_subscribed } }) {
    return this.leakDayService.retrieveDeviceLeakDayCountTotals(
      date_range,
      { leak_status, is_subscribed }
    );
  }

}

export default new DIFactory(new ControllerWrapper(LeakDayController), [LeakDayService]);