import _ from 'lodash';
import ZITResultTable from './ZITResultTable';
import ICDService from '../icd/ICDService';
import NotFoundException from '../utils/exceptions/NotFoundException'
import DIFactory from  '../../../util/DIFactory';

class ZITResultService {

  constructor(zitResultTable, icdService) {
    this.zitResultTable = zitResultTable;
    this.icdService = icdService;
  }

  /**
   * Query set ZITResult with same hashkey.
   */
  retrieveByIcdId(icdId) {
    return this.zitResultTable.retrieveByIcdId({ icd_id: icdId });
  }
  
  retrieveByDeviceId(deviceId) {
    return this.icdService.lookupByDeviceId(deviceId)
      .then(icd => {
        if (icd) {
          return this.zitResultTable.retrieveByIcdId({ icd_id: icd.id });
        } else {
          return new Promise((resolve, reject) => reject(new NotFoundException('Device not found.')));
        }
      });
  }

  createByDeviceId(deviceId, test, data) {
    const { round_id, started_at, ended_at } = data;
    const startedAt = started_at && new Date(started_at * (this.isTimestampInMs(started_at) ? 1 : 1000));
    const endedAt = ended_at && new Date(ended_at * (this.isTimestampInMs(ended_at) ? 1 : 1000));

    return this.icdService.lookupByDeviceId(deviceId)
      .then(icd => {
        if (icd) {
          const timestamp = startedAt ? { started_at: startedAt.toISOString() } : { ended_at: endedAt.toISOString() };
          const payload = _.extend({ test }, _.omit(data, ['round_id', 'started_at', 'ended_at']), timestamp);
          const icd_id = icd.id;

          return this.zitResultTable.patch({ icd_id, round_id }, payload);
        } else {
          return new Promise((resolve, reject) => reject(new NotFoundException('Device not found.')));
        }
      });
  }

  isTimestampInMs(timestamp) {
    const twoWeeksInSeconds = 1209600;
    const nowInSeconds = Math.floor(new Date().getTime() / 1000);
    const secondsLimit = nowInSeconds + twoWeeksInSeconds;

    return timestamp > secondsLimit;
  }
}

export default new DIFactory(ZITResultService, [ZITResultTable, ICDService]);