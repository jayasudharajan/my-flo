import _ from 'lodash';
import moment from 'moment-timezone';
import ip from 'ip';
import InvalidIPException from './exceptions/InvalidIPException';
import config from '../../../config/config';

export function getAllControllerMethods(obj, methods = []) {
	return _.chain(obj)
		.keysIn()
		.filter(prop => 
			prop !== 'constructor' &&
			!prop.startsWith('_') &&
			_.isFunction(obj[prop])
		)
		.value();
}

export function fillTime(data, startTime, endTime, calcDelta, zeroFill = createZeroFill) {
    const first = data[0] || { time: startTime };
    const last = data[data.length - 1] || { time: startTime };
    const leftDelta = calcDelta(startTime, first.time) - 1;
    const rightDelta = calcDelta(endTime, last.time) - 1;
    const leftPad = zeroFill(leftDelta, startTime, true);
    const rightPad = zeroFill(rightDelta, last.time);
    const filledData = !data.length ?
        [{
            time: startTime,
            average_flowrate: 0,
            average_temperature: 0,
            average_pressure: 0,
            total_flow: 0
        }] : 
        data
            .reduce((acc, date) => {
                const lastDate = (acc[acc.length - 1] || {}).time;
                const delta = !lastDate ? 0 : (calcDelta(date.time, lastDate) - 1);
                const fill = zeroFill(delta, lastDate);

                return [...acc, ...fill, date];
            }, []);

    return [...leftPad, ...filledData, ...rightPad];
}

function createZeroFill(numRecords, fromTime) {
    return Array(Math.max(numRecords, 0)).fill(null)
        .map((__, i) => ({
            time: moment(fromTime).add(i + 1, 'hours').toISOString(),
            average_flowrate: 0,
            average_temperature: 0,
            average_pressure: 0,
            total_flow: 0
        }));
}

export function verifyIPAddress(user, req = {}) {

    if (!user._is_ip_restricted || !config.adminIpAddressWhitelist) {
        return Promise.resolve(user);
    }

    const ipAddresses = ((req.headers && req.headers['x-forwarded-for']) || (req.connection && req.connection.remoteAddress) || '')
        .split(',')
        .map(ipAddress => ipAddress.trim());
    const ipAddressWhitelist = config.adminIpAddressWhitelist
        .split(',')
        .map(ipAddress => ipAddress.trim());
    const isIPAllowed = _.some(
        ipAddresses, 
        remoteIpAddress => 
        ipAddressWhitelist.some(
            whitelistIpAddress => ip.isEqual(remoteIpAddress, whitelistIpAddress)
        )
    );

    if (!isIPAllowed) {
        return Promise.reject(new InvalidIPException());
    }

    return Promise.resolve(user);
}
