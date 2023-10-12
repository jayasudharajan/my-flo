import { errorTypes } from '../../../config/constants';
import ICDTable from '../../models/ICDTable';
import DIFactory from  '../../../util/DIFactory';

class ICDService {
  constructor(icdTable) {
    this.icdTable = icdTable;
  }

  lookupByDeviceId(deviceId, log)  {
    return this.icdTable.retrieveByDeviceId({ device_id: deviceId })
      .then(data => {
        const { Items } = data;

         if (Items.length) {
          return Items[0];
        } else {
          return new Promise((resolve, reject) => reject(errorTypes.ICD_NOT_FOUND));
        }
      });
  }
}

export default new DIFactory(ICDService, [ICDTable]);