import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import IrrigationScheduleService from './IrrigationScheduleService';
import DirectiveService from '../directives/DirectiveService';
import ICDService from '../icd-v1_5/ICDService';
import TIrrigationScheduleStatus from './models/TIrrigationScheduleStatus';
import AwayModeStateLogTable from './AwayModeStateLogTable';
import ical from 'ical-generator';
import moment from 'moment';
import uuid from 'uuid';
import NotFoundException from '../utils/exceptions/NotFoundException';

class AwayModeService {
  constructor(irrigationScheduleService, directiveService, icdService, awayModeStateLogTable) {
    this.irrigationScheduleService = irrigationScheduleService;
    this.directiveService = directiveService;
    this.icdService = icdService;
    this.awayModeStateLogTable = awayModeStateLogTable;
  }

  retrieveIrrigationSchedule(icdId) {
    return this.icdService.retrieve(icdId)
      .then(({ Item: { device_id } }) => {

        if (!device_id) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }

        return this.irrigationScheduleService.retrieveIrrigationSchedule(device_id);
      });
  }

  _logStateChange(icdId, isEnabled, times) {
    return this.awayModeStateLogTable.createLatest({
      icd_id: icdId,
      is_enabled: isEnabled,
      times
    });
  }

  _convertToICal(times) {
    const cal = ical({ domain: 'meetflo.com' });
    
    times
      .filter(times => times.length)
      .forEach(([startTime, endTime]) => {
        const eventStart = moment.utc(startTime, 'HH:mm:ss').toDate();
        const eventEnd = moment.utc(endTime, 'HH:mm:ss').isAfter(eventStart) ?
          moment.utc(endTime, 'HH:mm:ss').toDate() :
          moment.utc(endTime, 'HH:mm:ss').add(1, 'days').toDate();

        const event = cal.createEvent({
          start: eventStart,
          end: eventEnd,
        });

        event.repeating({ freq: 'DAILY', interval: 1 });
      });

    return cal.toString()
      .replace(/\r?\n/gi, '\n')
      .replace(/DTSTAMP:.*\n/gi, '')
      .replace(/UID:.*\n/gi, '')
      .replace(/SEQUENCE.*\n/gi, '')
      .replace(/SUMMARY:.*\n/gi, '');
  }

  enableDeviceAwayMode(icdId, times, userId, appUsed) {
    return this.directiveService.sendDirective('set-away-mode-config', icdId, userId, appUsed, {
      enabled: true,
      schedule: this._convertToICal(times)
    })
    .then(() => this._logStateChange(icdId, true, times));
  }

  disableDeviceAwayMode(icdId, userId, appUsed) {
    return this.directiveService.sendDirective('set-away-mode-config', icdId, userId, appUsed, {
      enabled: false
    })
    .then(() => this._logStateChange(icdId, false));
  }

  retrieveAwayModeState(icdId) {

    return this.awayModeStateLogTable.retrieveLatest(icdId)
      .then(({ Items: [state] }) => !_.isEmpty(state) ? state : ({
        icd_id: icdId,
        is_enabled: false
      }));
  }
}

export default new DIFactory(AwayModeService, [IrrigationScheduleService, DirectiveService, ICDService, AwayModeStateLogTable]);