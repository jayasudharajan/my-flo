const UserInfoIntentHandler = require('./UserInfoIntentHandler');
const moment = require('moment-timezone');
const _ = require('lodash');

class WaterConsumptionIntentHandler extends UserInfoIntentHandler {
  constructor(...args) {
    super(...args);
    this.authorizationResource = 'water usage';
  }
}

class WaterConsumptionTodayIntentHandler extends WaterConsumptionIntentHandler {

  retrieveInfo({ user, accessToken, timezone }) {
    const startDate = moment.tz(timezone || 'Etc/UTC').startOf('day').toISOString();

    return this._makeRequest({
      method: 'get',
      url: `${ this.url }/v2/water/consumption?userId=${user.id}&startDate=${startDate}&tz=${timezone}`,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })
    .then(response => {
      const gallons = Math.floor(
        (response.data.aggregations || {}).sumTotalGallonsConsumed || 0
      );
      const units = gallons === 1 ? 'gallon' : 'gallons';

      return `You have used ${ gallons } ${ units } today.`;
    });
  }
}

class WaterConsumptionThisMonthIntentHandler extends WaterConsumptionIntentHandler {

  retrieveInfo({ user, accessToken, timezone }) {
    const startDate = moment.tz(timezone || 'Etc/UTC').startOf('month').toISOString();

    return this._makeRequest({
      method: 'get',
      url: `${ this.url }/v2/water/consumption?userId=${user.id}&startDate=${startDate}&tz=${timezone}`,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })
    .then(response => {
      const gallons = Math.floor(
        (response.data.aggregations || {}).sumTotalGallonsConsumed || 0
      );
      const units = gallons === 1 ? 'gallon' : 'gallons';

      return `You have used ${ gallons } ${ units } this month.`;
    });
  }
}

class WaterMeasurementIntentHandler extends WaterConsumptionIntentHandler {

  retrieveInfo({ user, accessToken, timezone }) {
    const startDate = this.getStartDate(timezone || 'Etc/UTC');

    return this._makeRequest({
      method: 'get',
      url: `${ this.url }/v2/water/consumption?userId=${user.id}&startDate=${startDate}&interval=1m&tz=${timezone}`,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })
    .then(response => {
      const gallons = Math.floor(
        (response.data.aggregations || {}).sumTotalGallonsConsumed || 0
      );
      const units = gallons === 1 ? 'gallon' : 'gallons';
      return `Since ${ moment(startDate).format('MMMM') } ${ moment(startDate).format('Do') } ${ moment(startDate).format('YYYY') }, you have used ${ gallons } ${ units }.`;
    });
  }
}

class WaterConsumptionThisWeekIntentHandler extends WaterMeasurementIntentHandler {

  getStartDate(timezone) {
    if (moment.tz(timezone).isoWeekday() === 6) {
      return moment.tz(timezone).startOf('day').toISOString();
    } else {
      return moment.tz(timezone).isoWeekday(-1).startOf('day').toISOString();
    }
  }
}

class WaterConsumptionLast12MonthsIntentHandler extends WaterMeasurementIntentHandler {

  getStartDate(timezone) {
    return moment.tz(timezone).subtract(12, 'months').startOf('month').toISOString();
  }
}

exports.WaterConsumptionTodayIntentHandler = WaterConsumptionTodayIntentHandler;
exports.WaterConsumptionThisMonthIntentHandler = WaterConsumptionThisMonthIntentHandler;
exports.WaterConsumptionThisWeekIntentHandler = WaterConsumptionThisWeekIntentHandler;
exports.WaterConsumptionLast12MonthsIntentHandler = WaterConsumptionLast12MonthsIntentHandler;