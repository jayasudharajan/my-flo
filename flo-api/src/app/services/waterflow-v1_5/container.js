import { Container } from 'inversify';
import reflect from 'reflect-metadata';
import Influx from 'influx';
import ICDContainer from '../icd-v1_5/container';
import LocationContainer from '../location-v1_5/container';
import infoContainer from '../info/container';
import WaterflowService from './WaterflowService';
import TelemetryMeasurement from './models/TelemetryMeasurement';
import TelemetryHourlyMeasurement from './models/TelemetryHourlyMeasurement';
import Telemetry15MinuteMeasurement from './models/Telemetry15MinuteMeasurement';
import TransmissionRateHourlyMeasurement from './TransmissionRateHourlyMeasurement';
import { mergeContainers } from '../../../util/containerUtil';
import config from '../../../config/config';
import redis from 'redis';
import {getClient} from '../../../util/cache';

const container = [ICDContainer, LocationContainer, infoContainer].reduce(mergeContainers, new Container());
const influxDbClient = new Influx.InfluxDB({
	host: config.influxdb.host,
	port: config.influxdb.port,
	protocol: 'https',
	database: config.influxdb.database,
	username: config.influxdb.username,
	password: config.influxdb.password
});
const influxDbAnalyticsClient = new Influx.InfluxDB({
	host: config.influxdb.host,
	port: config.influxdb.port,
	protocol: 'https',
	database: config.influxdb.analyticsDatabase,
	username: config.influxdb.username,
	password: config.influxdb.password
});

container.bind(TelemetryMeasurement).to(TelemetryMeasurement);
container.bind(TelemetryHourlyMeasurement).to(TelemetryHourlyMeasurement);
container.bind(Telemetry15MinuteMeasurement).to(Telemetry15MinuteMeasurement);
container.bind(TransmissionRateHourlyMeasurement).to(TransmissionRateHourlyMeasurement);
container.bind(WaterflowService).to(WaterflowService);
container.bind(Influx.InfluxDB).toConstantValue(influxDbClient).whenTargetIsDefault();
container.bind(Influx.InfluxDB).toConstantValue(influxDbAnalyticsClient).whenTargetNamed('Analytics');

if (!container.isBound(redis.RedisClient)) {
	container.bind(redis.RedisClient).toConstantValue(getClient());
}

export default container;