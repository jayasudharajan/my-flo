import _ from 'lodash';
import moment from 'moment-timezone';
import DIFactory from '../../../util/DIFactory';
import LocationService from '../location-v1_5/LocationService';
import ICDService from '../icd-v1_5/ICDService';
import TelemetryMeasurement from './models/TelemetryMeasurement';
import TelemetryHourlyMeasurement from './models/TelemetryHourlyMeasurement';
import Telemetry15MinuteMeasurement from './models/Telemetry15MinuteMeasurement';
import TransmissionRateHourlyMeasurement from './TransmissionRateHourlyMeasurement';
import NotFoundException from '../utils/exceptions/NotFoundException';
import ServiceException from '../utils/exceptions/ServiceException';
import InfoService from '../info/InfoService';
import { getThisWeekStartEndTime, getLast28DaysStartEndTime, getLastDayStartDayTime, aggregateSummaryMeasurements, aggregateHours, combineMeasurementRecords, normalizeRecords, getLast12MonthsStartEndTime, groupRecordsBy } from './utils';
import redis from 'redis';

class WaterflowService {
	constructor(infoService, telemetryMeasurement, telemetryHourlyMeasurement, telemetry15MinMeasurement, transmissionRateHourlyMeasurement, locationService, icdService, redisClient) {
		this.infoService = infoService;
		this.telemetryMeasurement = telemetryMeasurement;
		this.telemetryHourlyMeasurement = telemetryHourlyMeasurement;
		this.telemetry15MinMeasurement = telemetry15MinMeasurement;
		this.transmissionRateHourlyMeasurement = transmissionRateHourlyMeasurement;
		this.locationService = locationService;
		this.icdService = icdService;
		this.redisClient = redisClient;
	}

	retrieveDailyWaterFlow(deviceId, timezone) {

		return this.retrieveLastDayMeasurements(deviceId, timezone, new Date().getTime())
			.then(measurements => {
				const hourlyTotalFlow = _.chunk(measurements, 4)
					.map(measurements => _.sumBy(measurements, 'total_flow'))
					.slice(0, 24);
				const rightPad = Array(24 - hourlyTotalFlow.length).fill(0);

				return [...hourlyTotalFlow, ...rightPad]
					.map(totalFlow => totalFlow.toFixed(10));
			});
	}

	retrieveDailyWaterFlowByDeviceId(deviceId) {
		return this._retrieveTimezoneByDeviceId(deviceId)
			.then(timezone => this.retrieveDailyWaterFlow(deviceId, timezone));
	}

	retrieveDailyTotalWaterFlow(deviceId, timezone) {
		return this.retrieveLastDayMeasurements(deviceId, timezone, new Date().getTime())
			.then(measurements => ({
				usage: _.sumBy(measurements, 'total_flow').toFixed(2)
			})) ;
	}

	retrieveDailyTotalWaterFlowByDeviceId(deviceId) {
		return this._retrieveTimezoneByDeviceId(deviceId)
			.then(timezone => this.retrieveDailyTotalWaterFlow(deviceId, timezone));
	}

	retrieveMonthlyUsage(deviceId, timezone = 'Etc/UTC', prevMonth = false) {
		const fromTime = moment().tz(timezone).subtract(prevMonth ? 1 : 0, 'months').toDate().getTime();

		return this._retrieveAggregatedFullMeasurements({
			deviceId,
			timezone,
			fromTime: fromTime,
			getStartEndTime: () => ({ 
				startTime: moment(fromTime).tz(timezone).startOf('month').toISOString(),
				endTime: moment(fromTime).tz(timezone).endOf('month').toISOString()
			}),
			retrieveHourlyMeasurements:	(...args) => this.telemetryHourlyMeasurement.retrieveMonthlyMeasurements(...args),
			maxRecords: moment(fromTime).tz(timezone).daysInMonth(),
			groupBy: (timezone, record) => groupRecordsBy(record, 'YYYY-MM', timezone),
			aggregate: aggregatedHours => aggregateSummaryMeasurements(aggregatedHours)
		})
		.then(measurements => ({
			usage: (measurements.length ? measurements[0].total_flow : 0.0).toFixed(10)
		}));
	}

	retrieveMonthlyUsageByDeviceId(deviceId, prevMonth) {
		return this._retrieveTimezoneByDeviceId(deviceId)
			.then(timezone => this.retrieveMonthlyUsage(deviceId, timezone, prevMonth));
	}

	retrieveLast24HoursConsumption(...args) {
		return this.telemetryHourlyMeasurement.retrieveLast24HoursConsumption(...args);
	}

	retrieveLast24HoursConsumptionByICDId(icdId, fromTime) {
		return this._retrieveDeviceIdByICDId(icdId)
			.then(deviceId => this.retrieveLast24HoursConsumption(deviceId, fromTime));
	}

	retrieveLast30DaysConsumption(...args) {
		return this.telemetryHourlyMeasurement.retrieveLast30DaysConsumption(...args);
	}

	retrieveLast30DaysConsumptionByICDId(icdId, fromTime) {
		return this._retrieveDeviceIdAndTimezoneByICDId(icdId)
			.then(({ device_id, timezone }) => this.retrieveLast30DaysConsumption(device_id, fromTime, timezone));
	}

	retrieveLast12MonthsConsumption(...args) {
		return this.telemetryHourlyMeasurement.retrieveLast12MonthsConsumption(...args);
	}

	retrieveLast12MonthsConsumptionByICDId(icdId, fromTime) {
		return this._retrieveDeviceIdAndTimezoneByICDId(icdId)
			.then(({ device_id, timezone }) => this.retrieveLast12MonthsConsumption(device_id, fromTime, timezone));
	}

	retrieveLast24HourlyAverages(...args) {
		return this.telemetryHourlyMeasurement.retrieveLast24HourlyAverages(...args);
	}

	retrieveLast24HourlyAveragesByICDId(icdId, fromTime) {
		return this._retrieveDeviceIdByICDId(icdId)
			.then(deviceId => this.retrieveLast24HourlyAverages(deviceId, fromTime));
	}

	retrieveLastWeekConsumption(...args) {
		return this.telemetryHourlyMeasurement.retrieveLastWeekConsumption(...args);
	}

	retrieveLastWeekConsumptionByICDId(icdId, fromTime) {
		return this._byICDId(icdId, fromTime, (...args) => 
			this.retrieveLastWeekConsumption(...args)
		);
	}

	retrieveLast28DaysConsumption(...args) {
		return this.telemetryHourlyMeasurement.retrieveLast28DaysConsumption(...args);
	}

	retrieveLast28DaysConsumptionByICDId(icdId, fromTime) {
		return this._byICDId(icdId, fromTime, (...args) => 
			this.retrieveLast28DaysConsumption(...args)
		);
	}

	retrieveLastDayConsumption(...args) {
		return this.telemetry15MinMeasurement.retrieveLastDayConsumption(...args);
	}

	retrieveLastDayConsumptionByICDId(icdId, fromTime) {
		return this._byICDId(icdId, fromTime, (...args) => 
			this.retrieveLastDayConsumption(...args)
		);
	}

	retrieveTransmittingDevices(_startTime, _endTime) {
		const endTime = _endTime || moment();
		const startTime = _startTime || moment(endTime).subtract(24, 'hours');

		if (Math.abs(moment(endTime).diff(startTime, 'hours')) > 24) {
			return Promise.reject(new ServiceException('Time period cannot exceed 24 hours.'));
		}

		return this.telemetryHourlyMeasurement.retrieveTransmittingDevices(startTime, endTime);
	}

	retrieveLastDayMeasurementsByICDId(icdId, fromTime) {
		return this._retrieveDeviceIdAndTimezoneByICDId(icdId)
			.then(({ device_id, timezone }) => {
				return this.retrieveLastDayMeasurements(device_id, timezone, fromTime);
			});
	}

	retrieveLastDayMeasurements(deviceId, timezone, fromTime) {		
		const { startTime, endTime } = getLastDayStartDayTime(fromTime, timezone);
		const now = new Date().toISOString();
		const startOfCurrentQuarterHour = 
			now >= startTime && 
			now <= endTime && 
			moment(now)
				.startOf('hour')
				.add(Math.floor(moment(now).minutes() / 15) * 15, 'minutes')
				.toISOString();

		return Promise.all([
			{ deviceId, timezone },
			this.telemetry15MinMeasurement.retrieveLastDayMeasurements(deviceId, fromTime, timezone),
			startOfCurrentQuarterHour && this.telemetryMeasurement.retrieveHourlySummaryMeasurements(deviceId, startOfCurrentQuarterHour, now)
		])
		.then(([{ deviceId, timezone }, lastDay15MinMeasurements, currentQuarterHourMeasurements]) => {
			const combinedMeasurements = currentQuarterHourMeasurements ?
				combineMeasurementRecords(lastDay15MinMeasurements, currentQuarterHourMeasurements) :
				lastDay15MinMeasurements;

			return normalizeRecords(deviceId, combinedMeasurements);
		});
	}

	retrieveLast24HoursMeasurements(deviceId, fromTime = new Date().getTime()) {
		const endTime = moment(fromTime).toISOString();
		const startTime = moment(endTime).subtract(24, 'hours').startOf('hour').toISOString();
		const startOfLastHour = moment(endTime).startOf('hour').toISOString();
		const lastQuarterHour = moment(startOfLastHour)
				.add(Math.floor(moment(endTime).minutes() / 15) * 15, 'minutes')
				.toISOString();

		return Promise.all([
			this.telemetry15MinMeasurement.retrieveSummaryMeasurements(deviceId, startTime, lastQuarterHour),
			this.telemetryMeasurement.retrieveHourlySummaryMeasurements(deviceId, lastQuarterHour, endTime)
		])
		.then(([last24Hour15MinMeasurements, currentHourMeasurement]) => {
			const aggregatedLast24HourMeasurements = aggregateHours(
				last24Hour15MinMeasurements,
				24,
				record => groupRecordsBy(record, 'YYYY-MM-DD-HH', 'Etc/UTC'),
				aggregatedHours => aggregateSummaryMeasurements(aggregatedHours)
			);

			const combinedLast24HourMeasurements = combineMeasurementRecords(
				aggregatedLast24HourMeasurements, 
				currentHourMeasurement
			);

			return normalizeRecords(deviceId, combinedLast24HourMeasurements);
		});
	}

	retrieveLast24HoursMeasurementsByICDId(icdId, fromTime)  {
		return this._retrieveDeviceIdByICDId(icdId)
			.then(deviceId => this.retrieveLast24HoursMeasurements(deviceId, fromTime));
	}

	retrieveLastWeekMeasurementsByICDId(icdId, fromTime) {
		return this._byICDId(icdId, fromTime, (...args) => 
			this.telemetryHourlyMeasurement.retrieveLastWeekMeasurements(...args)
		);
	}

	retrieveThisWeekMeasurementsByICDId(icdId, fromTime) {

		return this._retrieveAggregatedFullMeasurements({
			icdId,
			fromTime,
			getStartEndTime: getThisWeekStartEndTime,
			retrieveHourlyMeasurements:	(...args) => this.telemetryHourlyMeasurement.retrieveThisWeekHourlyMeasurements(...args),
			maxRecords: 7,
			groupBy: (timezone, record) => groupRecordsBy(record, 'YYYY-MM-DD', timezone),
			aggregate: aggregatedHours => aggregateSummaryMeasurements(aggregatedHours),
			normalize: (days, timezone) => days.map(({ time, ...data }) => ({
				...data,
				time: moment(time).tz(timezone).startOf('day').toISOString()
			}))
		});
	}

	retrieveLast28DaysMeasurementsByICDId(icdId, fromTime) {

		return this._retrieveAggregatedFullMeasurements({
			icdId,
			fromTime,
			getStartEndTime: getLast28DaysStartEndTime,
			retrieveHourlyMeasurements:	(...args) => this.telemetryHourlyMeasurement.retrieveLast28DaysMeasurements(...args),
			maxRecords: 28,
			groupBy: (timezone, record) => groupRecordsBy(record, 'YYYY-MM-DD', timezone),
			aggregate: aggregatedHours => aggregateSummaryMeasurements(aggregatedHours)
		});
	}

	retrieveLast12MonthsMeasurementsByICDId(icdId, fromTime) {

		return this._retrieveAggregatedFullMeasurements({
			icdId,
			fromTime,
			getStartEndTime: getLast12MonthsStartEndTime,
			retrieveHourlyMeasurements: (...args) => this.telemetryHourlyMeasurement.retrieveLast12MonthsMeasurements(...args),
			maxRecords: 12,
			groupBy: (timezone, record) => groupRecordsBy(record, 'YYYY-MM', timezone),
			aggregate: aggregatedHours => aggregateSummaryMeasurements(aggregatedHours)
		});
	}

	retrieveThisWeekHourlyMeasurementsByGroupId(groupId, fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
		const { startTime, endTime } = getThisWeekStartEndTime(fromTime, timezone);
		const now = new Date().toISOString();

		return this._pageThroughGroupDevices(
			groupId, 
			results => 
				this._retrieveThisWeekMeasurementsForPage(
					results.map(({ device_id }) => device_id), 
					startTime,
					endTime, 
					now, 
					timezone
				)
		)
		.then(pageResults => 
			_.zip(...pageResults)
				.map(day => ({ total_flow: _.sumBy(day, 'total_flow'), time: day[0].time }))
		);
	}

	_pageThroughGroupDevices(groupId, doForEachPage, page = 1, size = 100) {

		return this.infoService.icds.retrieveAll({
				size,
				page,
				filter: {
					'account.group_id': groupId
				}
		})
		.then(({ items, total }) => {
			const hasPagesRemaining = (size * (page - 1)) + items.length < total;

			return Promise.all([
				doForEachPage(items, page),
				hasPagesRemaining && this._pageThroughGroupDevices(groupId, doForEachPage, page + 1)
			]);
		})
		.then(([thisPageResult, subsequentPageResults]) => 
			[thisPageResult, ...(subsequentPageResults || [])]
		);
	}

	_retrieveThisWeekMeasurementsForPage(deviceIds, startTime, endTime, now, timezone) {
		const startOfCurrentHour = now >= startTime && now <= endTime && moment(now).tz(timezone).startOf('hour').toISOString();

		return Promise.all([
			this.telemetryHourlyMeasurement.retrieveCombinedTotalFlow(deviceIds, startTime, endTime),
			startOfCurrentHour && this.telemetry15MinMeasurement.retrieveCombinedTotalFlow(deviceIds, startOfCurrentHour, now),
			startOfCurrentHour && this.telemetryMeasurement.retrieveCombinedTotalFlow(deviceIds, startOfCurrentHour, now)
		])
		.then(([hourlyMeasurements, last45MinuteTotalFlow = {}, last15MinuteTotalFlow = {}]) => {
			const currentHour = startOfCurrentHour && 
				{
					total_flow: (last45MinuteTotalFlow.total_flow || 0) + (last15MinuteTotalFlow.total_flow || 0),
					time: startOfCurrentHour
				};

			const fullMeasurements = (
				currentHour ?
					hourlyMeasurements.map(({ time, ...data }) => ({
							time: _.isString(time) ? time : time.toISOString(),
							...(moment(time).diff(startOfCurrentHour, 'hours') == 0 ? currentHour : data)
					})) :
					hourlyMeasurements
				)
				.map(({ time, ...data }) => ({ 
					...data, 
					time: _.isString(time) ? time : time.toISOString() 
				}));

			return aggregateHours(
				fullMeasurements,
				7, 
				record => groupRecordsBy(record, 'YYYY-MM-DD', timezone),
				aggregatedHours => ({ ...aggregatedHours[0], total_flow: _.sumBy(aggregatedHours, 'total_flow') })
			);
		});
	}

	_retrieveCachedMeasurements(deviceId, startTime, endTime, retrieveHourlyMeasurements, now) {
		const cacheKey = [deviceId, startTime, endTime].join('_');

		return new Promise((resolve, reject) =>
			this.redisClient.get(cacheKey, (err, result) => 
				err ? reject(err) : resolve(result)
			)
		)
		.then(cacheResult => JSON.parse(cacheResult) ||
			retrieveHourlyMeasurements()
				.then(queryResult => {
					const secondsRemainingInCurrentHour = moment().endOf('hour').diff(now || new Date(), 'seconds');

					// Fire and forget
					this.redisClient.setex(cacheKey, secondsRemainingInCurrentHour, JSON.stringify(queryResult));

					return queryResult;
				})
		);
	}

	_retrieveFullMeasurements(deviceId, fromTime, timezone, getStartEndTime, retrieveHourlyMeasurements) {
		const { startTime, endTime } = getStartEndTime(fromTime, timezone);
		const now = new Date().toISOString();
		const startOfCurrentHour = now >= startTime && now <= endTime && moment(now).tz(timezone).startOf('hour').toISOString();

		return Promise.all([
			this._retrieveCachedMeasurements(
				deviceId,
				startTime,
				endTime,
				() => retrieveHourlyMeasurements(deviceId, fromTime, timezone),
				now
			),
			// retrieveHourlyMeasurements(deviceId, fromTime, timezone)
			startOfCurrentHour && this.telemetryMeasurement.retrieveHourlySummaryMeasurements(deviceId, startOfCurrentHour, now)
		])
		.then(([hourlyMeasurements, currentHourMeasurement]) => {

			return currentHourMeasurement ? 
				combineMeasurementRecords(hourlyMeasurements, currentHourMeasurement) :
				hourlyMeasurements;
		});
	}

	_aggregateMeasurements(deviceId, hourlyMeasurements, maxRecords, groupBy, aggregate, normalize) {
		const aggregatedMeasurements = aggregateHours(
			hourlyMeasurements,
			maxRecords,
			groupBy,
			aggregate
		);

		return normalize(normalizeRecords(deviceId, aggregatedMeasurements));
	}

	_retrieveAggregatedFullMeasurements({ icdId, deviceId, timezone, fromTime, getStartEndTime, retrieveHourlyMeasurements, maxRecords, groupBy, aggregate, normalize }) {
		return (
				deviceId ?
					(
						timezone ?
							Promise.resolve({ timezone, device_id: deviceId }) :
							this._retrieveTimezoneByDeviceId(deviceId).then(timezone => ({ timezone, device_id: deviceId }))
					) :
					this._retrieveDeviceIdAndTimezoneByICDId(icdId)
			)
			.then(({ device_id, timezone }) => 
				Promise.all([
					{ device_id, timezone },
					this._retrieveFullMeasurements(device_id, fromTime, timezone, getStartEndTime, retrieveHourlyMeasurements)
				])
			)
			.then(([{ device_id, timezone }, hourlyMeasurements]) => {
				return this._aggregateMeasurements(
					device_id, 
					hourlyMeasurements, 
					maxRecords, 
					(...args) => groupBy(timezone, ...args), 
					aggregate,
					normalize ? data => normalize(data, timezone) : data => data
				)
			});
	}

	_byICDId(icdId, fromTime, fn) {
		return this._retrieveDeviceIdAndTimezoneByICDId(icdId)
			.then(({ device_id, timezone }) => 
				fn(device_id, fromTime, timezone)
			);
	}

	_byLocationId(locationId, fromTime, fn) {
		return this._retrieveDevicesAndTimezoneByLocationId(locationId)
			.then(({ timezone, devices }) => {
				const promises = devices.map(({ device_id }) => 
					fn(device_id, fromTime, timezone)
				);

				return Promise.all(promises);
			})
			.then(results => {
				const data = _.zip(...results.map(({ data }) => data))
					.map(data => _.sum(data));

				return {
					...results[0],
					data
				};
			});
	}

	_retrieveDevicesAndTimezoneByLocationId(locationId) {

		return Promise.all([
			this.locationService.retrieveByLocationId(locationId),
			this.icdService.retrieveByLocationId(locationId)
		])
			.then(([{ Items: locations }, { Items: devices }]) => {
				if (!locations.length) {
					return Promise.reject(new NotFoundException('Location not found.'));
				} else if (!devices.length) {
					return Promise.reject(new NotFoundException('Device not found.'));
				}

				return { timezone: locations[0].timezone, devices };
			});
	}

	_retrieveDevicesByLocationId(locationId) {
		return this.icdService.retrieveByLocationId(locationId)
			.then(({ Items }) => {
				if (!Items.length) {
					return Promise.reject(new NotFoundException('Location not found.'));
				}

				return Items;
			});
	}

	_retrieveDeviceIdAndTimezoneByICDId(icdId) {
		return this.icdService.retrieve(icdId)
			.then(({ Item }) => {
				if (!Item) {
					return Promise.reject(new NotFoundException('Device not found.'));
				}

				const device_id = Item.device_id;

				return this.locationService.retrieveByLocationId(Item.location_id)
					.then(({ Items }) => {
						if (!Items.length) {
							return Promise.reject(new NotFoundException('Location not found'));
						}

						return {
							device_id,
							timezone: Items[0].timezone
						};
					});
			});
	}

	_retrieveDeviceIdByICDId(icdId) {
		return this.icdService.retrieve(icdId)
			.then(({ Item }) => {
				if (!Item) {
					return Promise.reject(new NotFoundException('Device not found.'));
				}

				return Item.device_id;
			});
	}

	_retrieveTimezoneByDeviceId(deviceId) {
		return this.icdService.retrieveByDeviceId(deviceId)
			.then(({ Items }) => {
				if (!Items.length) {
					return Promise.reject(new NotFoundException('Device not found.'));
				}

				return this.locationService.retrieveByLocationId(Items[0].location_id);
			})
			.then(({ Items }) => {
				if (!Items.length) {
					return Promise.reject(new NotFoundException('Location not found.'));
				}

				return Items[0].timezone;
			});
	}

	retrieveLast24HoursTransmissionRateHourlyByDeviceId(deviceId, from) {
		return this.transmissionRateHourlyMeasurement.retrieveLast24HoursRate(deviceId, from);
	}
}

export default DIFactory(WaterflowService, [InfoService, TelemetryMeasurement, TelemetryHourlyMeasurement, Telemetry15MinuteMeasurement, TransmissionRateHourlyMeasurement, LocationService, ICDService, redis.RedisClient]);