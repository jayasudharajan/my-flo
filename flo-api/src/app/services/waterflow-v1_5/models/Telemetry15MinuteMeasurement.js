import _ from 'lodash';
import Influx from 'influx';
import influxdbUtil from '../../../../util/influxdbUtil';
import DIFactory from '../../../../util/DIFactory';
import moment from 'moment-timezone';
import config from '../../../../config/config';
import { fillTime } from '../../utils/utils';

function createZeroFill(numRecords, fromTime) {
  return Array(Math.max(numRecords, 0)).fill(null)
      .map((__, i) => ({
        time: moment(fromTime).add((i + 1) * 15, 'minutes').toISOString(),
        average_flowrate: 0,
        average_temperature: 0,
        average_pressure: 0,
        total_flow: 0
      }));
}

function fill15Mins(data, startTime, endTime, calcDelta) {
	return fillTime(data, startTime, endTime, (time1, time2) => 
		Math.ceil(
			Math.abs(moment(time1).diff(time2, 'minutes', true)) / 15
		),
		createZeroFill
	);
}

class Telemetry15MinuteMeasurement {
	constructor(influxDbClient) {
		this.influxDbClient = influxDbClient;
	}

	_query(deviceId, startTime, endTime, projection) {
		const selection = projection.join(', ');
		const query = [
			`SELECT ${ selection } FROM ${ config.influxdb.telemetry15mMeasurement }`,
			`WHERE did::tag = '${ influxdbUtil.sanitize(deviceId) }'`,
			`AND time <= '${ endTime }'`,
			`AND time >= '${ startTime }'`,
			`ORDER BY time ASC`
		].join(' ');

		return this.influxDbClient.query(query);
	}

	retrieveSummaryMeasurements(deviceId, startTime, endTime, projection = ['*']) {
		return this._query(deviceId, startTime, endTime, projection)
			.then(results => fill15Mins(results, startTime, endTime));
	}

	retrieveLastDayConsumption(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const endTime = moment(parseInt(fromTime)).tz(timezone).endOf('day').toISOString();
		const startTime = moment(endTime).tz(timezone).startOf('day').toISOString();

		return this._query(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fill15Mins(results, startTime, endTime);
				const data = filledResults.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveMonthlyUsage(deviceId, timezone = 'Etc/UTC') {
		const firstOfMonth = moment().tz(timezone).startOf('month').toISOString();
		const query = [
			`SELECT SUM(total_flow) AS totalWaterFlow FROM ${ config.influxdb.telemetry15mMeasurement }`,
			`WHERE time >= '${ firstOfMonth }'`,
			`AND did::tag = '${ influxdbUtil.sanitize(deviceId) }'`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => {
				const monthlyUsage = results[0];

				return { 
					usage: (monthlyUsage ? monthlyUsage.totalWaterFlow : 0).toFixed(10)
				};
			});		
	}

	retrieveLastDayMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const endTime = moment(parseInt(fromTime)).tz(timezone).endOf('day').toISOString();
		const startTime = moment(endTime).tz(timezone).startOf('day').toISOString();

		return this._query(deviceId, startTime, endTime, ['*'])
			.then(results => 
				fill15Mins(results, startTime, endTime)
					.map(({ time, ...data }) => ({
						...data,
						did: deviceId,
						time: _.isString(time) ? time : time.toISOString()
					}))
			)
	}

	retrieveCombinedTotalFlow(deviceIds, startTime, endTime) {
		const deviceIdClause = deviceIds.map(deviceId => `did::tag = '${ influxdbUtil.sanitize(deviceId) }'`).join(' OR ');
		const query = [
			`SELECT SUM(total_flow) AS total_flow FROM ${ config.influxdb.telemetry15mMeasurement }`,
			`WHERE time >= '${ moment(startTime).toISOString() }'`,
			`AND time <= '${ moment(endTime).toISOString() }'`,
			`AND (${ deviceIdClause })`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => results[0]);
	}
}

export default DIFactory(Telemetry15MinuteMeasurement, [['Analytics', Influx.InfluxDB]]);