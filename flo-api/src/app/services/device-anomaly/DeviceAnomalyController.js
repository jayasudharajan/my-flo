import DeviceAnomalyService from './DeviceAnomalyService'
import DIFactory from '../../../util/DIFactory';
import {ControllerWrapper} from '../../../util/controllerUtils';
import _ from 'lodash' ;
import moment from 'moment';


class DeviceAnomalyController {

  constructor(deviceAnomalyService) {
    this.deviceAnomalyService = deviceAnomalyService;
  }

  handleDeviceAnomalyEvent({params: {type}, body: event, query}) {
    const values = _.mapValues(query, val => {
      const numericValue = new Number(val).valueOf();

      return !numericValue && numericValue !== 0 ? val : numericValue;
    });
    return this.deviceAnomalyService.handleEvent(parseInt(type), event, values);
  }

  retrieveByAnomalyTypeAndDateRange({params: {type}, query: {start_date = moment().subtract(1, 'days').toISOString(), end_date = moment().add(1, 'days').toISOString()}}) {
    return this.deviceAnomalyService.retrieveByTypeAndDateRange(parseInt(type), start_date, end_date)
  }

}

export default new DIFactory(new ControllerWrapper(DeviceAnomalyController), [DeviceAnomalyService]);
