import moment from 'moment';
import momenttz from 'moment-timezone';
var config = require('../config/config');

/**
 * NOTE: Any time, date data in Influxdb is in UTC.
 * Every query time, date needs to be translated to UTC.
 */

let self = module.exports = {
    /**
     * Remove anything non-alphanumeric
     */
    sanitize: function(str) {
        var re = /[^0-9a-z]/gi;
        return str.replace(re, '');
    },

    getTelemetryTable: function() {
        return config.influxdb.rawTelemetryMeasurement;
    },

    /**
     * Returns InfluxQL date pattern
     */
    getQueryDateFormat: function() {
        return "YYYY-MM-DD kk:mm:ss.SSS";
    },

    /**
     * Returns given date in InfluxQL format
     */
    getQueryDate: function(momentjsDate) {
        return moment.utc(momentjsDate).toISOString();
    },

    /**
     * Returns the end of CURRENT day in UTC (as a InfluxQL date) for the given timezone.
     * tzIANACode: America/Los_Angeles
     * Returns: 2016-07-25 06:59:59.999
     */
    currentDayMidnight: function(tzIANACode) {
        let tzUtc = "Etc/UTC";
        return self.getQueryDate(momenttz().tz(tzIANACode).endOf('day').add(1, 'days').startOf('day').tz(tzUtc));
    },

    /**
     * Returns the end of PREVIOUS day in UTC (as a InfluxQL date) for the given timezone.
     * tzIANACode: America/Los_Angeles
     * Returns: 2016-07-25 06:59:59.999
     */
    previousDayMidnight: function(tzIANACode) {
        let tzUtc = "Etc/UTC";
        return self.getQueryDate(momenttz().tz(tzIANACode).endOf('day').add(1, 'days').startOf('day').tz(tzUtc).subtract(1, 'days'));
    },

    getConfig: function() {
        return {
            host : config.influxdb.host,
            port : config.influxdb.port,
            protocol : "https",
            database : config.influxdb.database,
            username : config.influxdb.username,
            password : config.influxdb.password
        }
    }

};
