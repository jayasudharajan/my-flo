import _ from 'lodash';
import moment from 'moment-timezone';

export function getThisWeekStartEndTime(fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
	const startDate = moment(parseInt(fromTime)).tz(timezone);
	const startTime = (startDate.day() === 6 ? moment(startDate) : moment(startDate).day(-1)).tz(timezone).startOf('day'); // Saturday 00:00:00.00
	const endTime = moment(startTime).add(6, 'days').tz(timezone).endOf('day');

	return { startTime: startTime.toISOString(), endTime: endTime.toISOString() };
}

export function getLast28DaysStartEndTime(fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
	const startDate = moment(parseInt(fromTime)).tz(timezone);
	const endTime = moment(startDate).tz(timezone).endOf('day').toISOString();
	const startTime = moment(endTime).tz(timezone).subtract(28, 'days').startOf('day').toISOString();

	return { startTime, endTime };
}

export function getLastDayStartDayTime(fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
	const endTime = moment(parseInt(fromTime)).tz(timezone).endOf('day').toISOString();
	const startTime = moment(endTime).tz(timezone).startOf('day').toISOString();
	
	return { endTime, startTime };
}

export function getLast12MonthsStartEndTime(fromTime = new Date().getTime(), timezone = 'Etc/UTC') {
	const endTime = moment(parseInt(fromTime)).tz(timezone).endOf('day');
	const startTime = moment(endTime).tz(timezone).subtract(1, 'years').startOf('day');

	return { startTime: startTime.toISOString(), endTime: endTime.toISOString() };
}

export function aggregateHours(data, maxRecords, groupBy, aggregate) {
	return _.chain(data)
		.groupBy(groupBy)
		.map(aggregate)
		.sortBy('time')
		.takeRight(maxRecords)
		.value();
}

export function compareTimes(last, current, format, timezone) {	
	return moment(last.time).tz(timezone).format(format) < moment(current.time).tz(timezone).format(format);
}

export function groupRecordsBy(record, format, timezone = 'Etc/UTC') {
	return moment(record.time).tz(timezone).format(format);
}

export function aggregateSummaryMeasurements(aggregatedHours = []) {
	const nonZeroData = aggregatedHours
		.filter(({ average_temperature, average_pressure, average_flowrate, total_flow }) => 
			_.sum([average_temperature, average_pressure, average_flowrate, total_flow]) > 0
		);

	return {
		did: (aggregatedHours[0] || {}).did,
		time: (aggregatedHours[0] || {}).time,
		average_temperature: _.meanBy(nonZeroData, 'average_temperature') || 0,
		average_pressure:  _.meanBy(nonZeroData, 'average_pressure') || 0,
		average_flowrate:  _.meanBy(nonZeroData, 'average_flowrate') || 0,
		total_flow:  _.sumBy(nonZeroData, 'total_flow') || 0
	};		
}

export function combineMeasurementRecords(measurements, currentMeasurement) {
	const currentTime = currentMeasurement && currentMeasurement.time;
	
	return !currentTime ? measurements : measurements
		.reduce((acc, hour) => {
			const prevRecord = acc.length && acc[acc.length - 1];

			return (prevRecord && moment(currentTime).diff(prevRecord.time) >= 0 && moment(currentTime).isBefore(hour.time)) ?
				[
					...acc.slice(0, acc.length - 1),
					currentMeasurement,
					hour
				] : 
				[
					...acc,
					hour
				];
		}, []);
}

export function normalizeRecords(deviceId, records = []) {
	return records.map(({ time, ...data }) => ({
			...data,
			did: deviceId,
			time: _.isString(time) ? time : time.toISOString()
		}));
}