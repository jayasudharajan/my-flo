import DIFactory from  '../../../util/DIFactory';
import * as alerts from '../alerts/alerts';

class AlertsService {
  constructor() {

  }

  getFullActivityLog(icd_id, { size, page, filter }) {
    return alerts.getFullActivityLog(icd_id, { size, page, filter });
  }
}

export default AlertsService;

