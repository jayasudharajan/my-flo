import Influx from 'influx';
import DIFactory from '../../../util/DIFactory';
import moment from 'moment-timezone';

class TransmissionRateHourlyMeasurement {
	constructor(influxDbClient) {
		this.influxDbClient = influxDbClient;
	}

	retrieveLast24HoursRate(deviceId, from = new Date().toISOString()) {
		const endTime = moment(from).toISOString();
		const startTime = moment(endTime).subtract(24, 'hours').startOf('hour').toISOString();
		const query = [
			`SELECT * FROM transmission_rate_hourly`,
			`WHERE did::tag = '${ deviceId }'`,
			`AND time < '${ endTime }' AND time >= '${ startTime }'`
		].join(' ');

		return this.influxDbClient.query(query)
			.then(results => ({
				data: results.map(({ time, ...data }) => ({
					...data,
					time: time.toISOString()
				}))
			}));
	}
}

export default new DIFactory(TransmissionRateHourlyMeasurement, [['Analytics', Influx.InfluxDB]]);