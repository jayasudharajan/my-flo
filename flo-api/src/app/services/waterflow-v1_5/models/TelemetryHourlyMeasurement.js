import _ from 'lodash';
import Influx from 'influx';
import influxdbUtil from '../../../../util/influxdbUtil';
import DIFactory from '../../../../util/DIFactory';
import moment from 'moment-timezone';
import config from '../../../../config/config';
import { fillTime } from '../../utils/utils';
import { getThisWeekStartEndTime, getLast28DaysStartEndTime, aggregateHours, aggregateSummaryMeasurements, getLast12MonthsStartEndTime, groupRecordsBy } from '../utils';


function getTimePeriod(fromTime, numHours) {
    const endTime = moment(fromTime ? parseInt(fromTime) : undefined).subtract(1, 'hours').endOf('hour').toISOString();
    const startTime = moment(endTime).subtract(numHours, 'hours').startOf('hour').toISOString();

    return { startTime, endTime };
}

function fillHours(data, startTime, endTime) {

	return fillTime(data, startTime, endTime, (time1, time2) => 
		Math.ceil(Math.abs(moment(time1).diff(time2, 'hours', true)))
	);
}

function fillMonths(data, startTime, endTime, timezone) {

	return fillTime(
		data, 
		startTime, 
		endTime, 
		(time1, time2) => 
			Math.ceil(Math.abs(moment(time1).diff(time2, 'months', true))),
		(numRecords, fromTime) => 
			Array(Math.max(numRecords, 0)).fill(null)
        .map((__, i) => ({
          time: moment(fromTime).tz(timezone).add(i + 1, 'months').startOf('month').toISOString(),
          average_flowrate: 0,
          average_temperature: 0,
          average_pressure: 0,
          total_flow: 0
        }))
	);
}

function fillDays(data, startTime, endTime, timezone) {

	return fillTime(
		data, 
		startTime, 
		endTime, 
		(time1, time2) => 
			Math.ceil(Math.abs(moment(time1).diff(time2, 'days', true))),
		(numRecords, fromTime, isFromLeft) => 
			Array(Math.max(isFromLeft && numRecords ? numRecords + 1 : numRecords, 0)).fill(null)
        .map((__, i) => ({
          time: moment(fromTime).tz(timezone).add(isFromLeft ? i : i + 1, 'days').startOf('day').toISOString(),
          average_flowrate: 0,
          average_temperature: 0,
          average_pressure: 0,
          total_flow: 0
        }))
	);
}

class TelemetryHourlyMeasurement {
	constructor(influxDbClient) {
		this.influxDbClient = influxDbClient;
	}

	_queryTelemetryHourly(deviceId, startTime, endTime, projection) {
	    const selection = projection.join(', ');
	    const query = [
	        `SELECT ${ selection } FROM ${ config.influxdb.telemetryHourlyMeasurement }`, //${ config.influxdb.telemetryHourlyPath }`,
	        `WHERE did::tag = '${ influxdbUtil.sanitize(deviceId) }'`,
	        `AND time <= '${ endTime }'`, 
	        `AND time >= '${ startTime }'`,
	        `ORDER BY time ASC`
	    ].join(' ');

	    return this.influxDbClient.query(query);
	}

	aggregateSummedTotalFlow(aggregatedHours = []) {
		return aggregatedHours.slice(1)
			.reduce(
				({ total_flow: accTotalFlow = 0, ...accData } , { total_flow = 0, ...data }) => ({
					...data,
					...accData,
					total_flow: accTotalFlow + total_flow
				}), 
				aggregatedHours[0]
		);
	}

	retrieveLast24HoursConsumption(deviceId, fromTime = new Date().getTime()) {
		const { startTime, endTime } = getTimePeriod(fromTime, 24);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const data = filledResults.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLast30DaysConsumption(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const hours = 30 * 24;
		const { startTime, endTime } = getTimePeriod(fromTime, hours);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const aggregatedData = aggregateHours(
					filledResults,
					30,
					hour => groupRecordsBy(hour, 'YYYY-MM-DD', timezone),
					aggregatedHours => this.aggregateSummedTotalFlow(aggregatedHours)
				);
				const data = aggregatedData.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLast12MonthsConsumption(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const hours = 365 * 24;
		const { startTime, endTime } = getTimePeriod(fromTime, hours);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const aggregatedData = aggregateHours(
					filledResults,
					12,
					hour => groupRecordsBy(hour, 'YYYY-MM', timezone),
					aggregatedHours => this.aggregateSummedTotalFlow(aggregatedHours)
				);
				const data = aggregatedData.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLast24HourlyAverages(deviceId, fromTime = new Date().getTime()) {
		const { startTime, endTime } = getTimePeriod(fromTime, 24);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['average_flowrate', 'average_pressure', 'average_temperature'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const flow_rate = filledResults.map(({ average_flowrate }) => average_flowrate);
				const pressure = filledResults.map(({ average_pressure }) => average_pressure);
				const temperature = filledResults.map(({ average_temperature }) => average_temperature);
				const data = { flow_rate, pressure, temperature }; 

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLastWeekConsumption(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const startTime = moment(parseInt(fromTime)).tz(timezone).day(-1).startOf('day').toISOString(); // Saturday 00:00:00.00
		const endTime = moment(startTime).add(6, 'days').tz(timezone).endOf('day').toISOString();
	
		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const aggregatedData = aggregateHours(
					filledResults,
					7,
					hour => groupRecordsBy(hour, 'YYYY-MM-DD', timezone),
					aggregatedHours => this.aggregateSummedTotalFlow(aggregatedHours)
				);
				const data = aggregatedData.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLast28DaysConsumption(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const endTime = moment(parseInt(fromTime)).endOf('hour').toISOString();
		const startTime = moment(endTime).tz(timezone).subtract(28, 'days').startOf('day').toISOString();

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['total_flow'])
			.then(results => {
				const filledResults = fillHours(results, startTime, endTime);
				const aggregatedData = aggregateHours(
					filledResults,
					28,
					hour => groupRecordsBy(hour, 'YYYY-MM-DD', timezone),
					aggregatedHours => this.aggregateSummedTotalFlow(aggregatedHours)
				);
				const data = aggregatedData.map(({ total_flow }) => total_flow);

				return { start_time: startTime, end_time: endTime, data };
			});
	}

	retrieveLastWeekMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const startTime = moment(parseInt(fromTime)).tz(timezone).day(-1).startOf('day').toISOString(); // Saturday 00:00:00.00
		const endTime = moment(startTime).add(6, 'days').tz(timezone).endOf('day').toISOString();
	
		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['*'])
			.then(results => {
				const filledResults = fillDays(results, startTime, endTime, timezone);
				
				return filledResults.map(({ time, ...data }) => ({
					...data,
					did: deviceId,
					time: _.isString(time) ? time : time.toISOString()
				}));

			});
	}

	retrieveThisWeekHourlyMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const { startTime, endTime } = getThisWeekStartEndTime(fromTime, timezone);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['*'])
			.then(results => fillDays(results, startTime, endTime, timezone));
	}

	retrieveLast28DaysMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const { startTime, endTime } = getLast28DaysStartEndTime(fromTime, timezone);

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['*'])
			.then(results => {
				const filledResults = fillDays(results, startTime, endTime, timezone);

				return filledResults.map(({ time, ...data }) => ({
					...data,
					did: deviceId,
					time: _.isString(time) ? time : time.toISOString()
				}));
			});
	}

	retrieveLast12MonthsMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const { startTime, endTime } = getLast12MonthsStartEndTime(fromTime, timezone);
		const hours = moment(endTime).diff(startTime, 'hours');

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['*'])
			.then(results => {
				const filledResults = fillMonths(results, startTime, endTime, timezone);

				return filledResults.map(({ time, ...data }) => ({
					...data,
					did: deviceId,
					time: _.isString(time) ? time : time.toISOString()
				}));
			})
	}

	retrieveMonthlyMeasurements(deviceId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const startTime = moment(fromTime).tz(timezone).startOf('month').toISOString();
		const endTime = moment(fromTime).tz(timezone).endOf('month').toISOString();
		const numDays = moment(fromTime).tz(timezone).daysInMonth();

		return this._queryTelemetryHourly(deviceId, startTime, endTime, ['*'])
			.then(results => {
				
				return results.map(({ time, ...data }) => ({
					...data,
					did: deviceId,
					time: _.isString(time) ? time : time.toISOString()
				}));

			});		
	}

	retrieveTransmittingDevices(startTime, endTime) {
		const telemetryTableName = influxdbUtil.getTelemetryTable(startTime, endTime);

		const query = [
			`SELECT * FROM ${ config.influxdb.telemetryHourlyMeasurement }`,
			`WHERE time >= '${ moment(startTime).toISOString() }'`,
			`AND time < '${ moment(endTime).toISOString() }'`,
			`GROUP BY did LIMIT 1`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => ({
				device_ids: results.map(({ did }) => did)
			}));
	}

	retrieveCombinedTotalFlow(deviceIds, startTime, endTime) {
		const deviceIdClause = deviceIds.map(deviceId => `did = '${ influxdbUtil.sanitize(deviceId) }'`).join(' OR ');
		const query = [
			`SELECT total_flow FROM ${ config.influxdb.telemetryHourlyMeasurement }`,
			`WHERE time >= '${ moment(startTime).toISOString() }'`,
			`AND time <= '${ moment(endTime).toISOString() }'`,
			`AND (${ deviceIdClause })`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => 
				fillHours(results, startTime, endTime)
					.map(data => _.pick(data, ['time', 'total_flow']))
			);
	}
}

export default DIFactory(TelemetryHourlyMeasurement, [['Analytics', Influx.InfluxDB]]);