import DIFactory from '../../../util/DIFactory';
import MicroLeakTestTimeTable from './MicroLeakTestTimeTable';
import DirectiveService from '../directives/DirectiveService';
import NotFoundException from '../utils/exceptions/NotFoundException';
import ICDService from '../icd-v1_5/ICDService';
import moment from 'moment';

class MicroLeakTestTimeService {
  constructor(microLeakTestTimeTable, icdService, directiveService) {
    this.microLeakTestTimeTable = microLeakTestTimeTable;
    this.directiveService = directiveService;
    this.icdService = icdService;
  }

  _retrieveIcdByDeviceId(deviceId) {
    return this.icdService.retrieveByDeviceId(deviceId)
      .then(({ Items: icds }) => {
        if (icds.length < 1) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }
        return icds[0];
      });
  }

  _timesToDirectiveConfigs(timesInMinutesAfterMidnight) {
    const oneHourInMinutes = 60;

    return timesInMinutesAfterMidnight.map(minutesAfterMidnight => ({
      enabled: true,
      start_time: moment().startOf('day').add(minutesAfterMidnight, 'minutes').format('HH:mm'),
      end_time:  moment().startOf('day').add(minutesAfterMidnight + oneHourInMinutes, 'minutes').format('HH:mm'),
      allowed_percent_of_pressure_to_drop: 3.0,
      allowed_slope_diff: 0.6,
      max_round_duration: 480000
    }));
  }

  retrievePendingTimesConfig() {
    return this
      .microLeakTestTimeTable
      .retrieveByIsDeployed(false)
      .then(({ Items: items }) => this._mapRetrieveResult(items));
  }

  deployTimesConfig(deviceId, data, userId, appUsed) {
    const directive = "update-health-test-config-v2";
    const created_at = new Date().toISOString();
    const microleakTestTimeRecord = {
      device_id: deviceId,
      created_at,
      times: data.times,
      compute_time: data.compute_time,
      reference_time: data.reference_time,
      created_at_device_id: `${created_at}_${deviceId}`,
      is_deployed: 0
    };

    return this._retrieveIcdByDeviceId(deviceId)
      .then(icd => {
        return Promise.all([
          this.microLeakTestTimeTable.create(microleakTestTimeRecord),
          this.directiveService.sendDirective(
            directive,
            icd.id,
            userId,
            appUsed,
            {
              configs: this._timesToDirectiveConfigs(data.times)
            }
          )
        ]);
      });
  }
  _mapRetrieveResult(items) {
    if (!items || items.length < 1) {
      return {
        data: []
      };
    }
    return {
      data: items
    };
  }
}

export default DIFactory(
  MicroLeakTestTimeService,
  [ MicroLeakTestTimeTable, ICDService, DirectiveService ]
);


