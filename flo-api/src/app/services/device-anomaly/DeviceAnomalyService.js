import _ from 'lodash';
import DIFactory from '../../../util/DIFactory';
import DeviceAnomalyEventTable from './DeviceAnomalyEventTable';
import DeviceAnomalyTypes from './models/TDeviceAnomaly';


class DeviceAnomalyService {

  constructor(deviceAnomalyEventTable) {
    this.deviceAnomalyEventTable = deviceAnomalyEventTable;
  }

  handleEvent(anomalyType, anomalyAlert, anomalyValues) {
    const record = this._buildRecords(anomalyType, anomalyAlert, anomalyValues)[0];
    return this.deviceAnomalyEventTable.create(record)
  }

  _buildRecords(anomalyType, anomalyEvent, anomalyValues = {}) {
    const {message, duration, level} = anomalyEvent;
    const {name, columns, values, tags} = anomalyEvent.data.series[0];
    const tagData = _.omit(tags, ['did']);

    return values
      .map(row => {
        const columnData = _.zipObject(columns, row);

        return {
          ...tagData,
          ...columnData,
          ...anomalyValues,
          device_id: tags.did,
          type: anomalyType,
          name,
          level,
          message,
          duration
        };
      });
  }

  retrieveByTypeAndDateRange(anomalyType, startTime, endTime) {
    return this.deviceAnomalyEventTable.retrieveByEventTypeAndTime(anomalyType, startTime, endTime).then(results => results.Items)
  }
}

export default new DIFactory(DeviceAnomalyService, [DeviceAnomalyEventTable]);