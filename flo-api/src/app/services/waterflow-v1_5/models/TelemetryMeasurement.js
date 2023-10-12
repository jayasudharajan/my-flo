import Influx from 'influx';
import influxdbUtil from '../../../../util/influxdbUtil';
import DIFactory from '../../../../util/DIFactory';
import moment from 'moment-timezone';

class TelemetryMeasurement {

	constructor(influxDbClient) {
		this.influxDbClient = influxDbClient;
	}

	retrieveHourlySummaryMeasurements(deviceId, _startTime, endTime = new Date().toISOString()) {
		const startTime = _startTime || moment(endTime).startOf('hour').toISOString();
		const telemetryTableName = influxdbUtil.getTelemetryTable(startTime, endTime);
		const selection = [
			'SUM(f) AS total_flow',
			'MEAN(wf) AS average_flowrate',
			'MEAN(t) AS average_temperature',
			'MEAN(p) AS average_pressure'
		].join(', ');
		const query = [
			`SELECT ${ selection } FROM ${ telemetryTableName }`,
			`WHERE time >= '${ startTime }' AND time <= '${ endTime }'`,
			`AND did::tag = '${ influxdbUtil.sanitize(deviceId) }'`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => results[0]);
	}

	retrieveCombinedTotalFlow(deviceIds, startTime, endTime) {
		const telemetryTableName = influxdbUtil.getTelemetryTable(startTime, endTime);
		const deviceIdClause = deviceIds.map(deviceId => `did::tag = '${ influxdbUtil.sanitize(deviceId) }'`).join(' OR ');
		const query = [
			`SELECT SUM(f) AS total_flow FROM ${ telemetryTableName }`,
			`WHERE time >= '${ moment(startTime).toISOString() }'`,
			`AND time <= '${ moment(endTime).toISOString() }'`,
			`AND (${ deviceIdClause })`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => results[0]);
	}
}

export default DIFactory(TelemetryMeasurement, [Influx.InfluxDB]);

