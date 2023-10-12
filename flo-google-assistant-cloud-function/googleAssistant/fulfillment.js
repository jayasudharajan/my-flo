// See https://github.com/dialogflow/dialogflow-fulfillment-nodejs
// for Dialogflow fulfillment library docs, samples, and to report issues
'use strict';

const functions = require('firebase-functions');
const {WebhookClient} = require('dialogflow-fulfillment');
const {Card, Suggestion} = require('dialogflow-fulfillment');
const axios = require('axios');
const moment = require('moment-timezone');
const _ = require('lodash');

process.env.DEBUG = 'dialogflow:debug';

//app vars
const floApiV2Url = 'https://api-gw.meetflo.com/api/v2/';
const followUp = 'Anything else?';
const dateFormat = 'YYYY-MM-DDTHH:mm:ss.SSS';
const defaultTimezone = 'Etc/UTC';
const ProductType = {
  DETECTOR: 'puck_oem',
  SHUTOFF: 'flo_device_v2'
};

exports.dialogflowFirebaseFulfillment = functions.https.onRequest((request, response) => {
  const agent = new WebhookClient({ request, response });
  console.log('Dialogflow Request headers: ' + JSON.stringify(request.headers));
  console.log('Dialogflow Request body: ' + JSON.stringify(request.body));
  const token = 'Bearer '+ request.body.originalDetectIntentRequest.payload.user.accessToken;


  axios.defaults.baseURL = floApiV2Url;
  axios.defaults.headers.common['Authorization'] = token;
  axios.defaults.timeout = 50000;

  function getUserInfo() {
    return  axios.get('users/me?expand=account')
      .then(response=> {
        if(response.data !== '' && response.data.id !== undefined && response.data.id !== ""){
          return response.data;
        } else {
          return Promise.reject('Unable to find user data');
        }
      });
  }

  function getSettingsByPeriod(period, tz, previous = false) {
    switch (period) {
      case "last_day": {
        const start = previous ? moment().subtract(24, 'hours') : moment();
        const end = previous ? moment().subtract(24, 'hours') : moment();
        return {
          startDate: start.startOf('day').format(dateFormat),
          endDate: end.endOf('day').format(dateFormat),
          interval: '1h',
        };
      }
      case "last_24_hours": {
        const start = previous ? moment().tz(tz).subtract(48, 'hours') : moment().tz(tz).subtract(24, 'hours');
        const end = previous ? moment().tz(tz).subtract(24, 'hours') : moment().tz(tz);
        return {
          startDate: start.startOf('hour').format(dateFormat),
          endDate: end.startOf('hour').format(dateFormat),
          interval: '1h',
        };
      }
      case "this_week": {
        const start = previous ? moment().subtract(7, 'days').startOf('week') : moment().startOf('week');
        const end = previous ? moment().subtract(7, 'days').endOf('week') : moment().endOf('week');
        const today = previous ? moment().subtract(7, 'days') : moment();
        start.subtract(1, 'day');
        end.subtract(1, 'day');
        const isBetween = today.isBetween(start.clone(), end.clone());
        return {
          startDate: isBetween ? start.format(dateFormat) : start.add(1, 'week').format(dateFormat),
          endDate: isBetween ? end.format(dateFormat) : end.add(1, 'week').format(dateFormat),
          interval: '1d',
        };
      }
      case "last_28_days": {
        const start = previous ? moment().subtract(56, 'days') : moment().subtract(28, 'days');
        const end = previous ? moment().subtract(28, 'days') : moment();
        return {
          startDate: start.add(1, 'days').startOf('day').format(dateFormat),
          endDate: end.endOf('day').format(dateFormat),
          interval: '1d',
        };
      }
      case "last_12_months": {
        const start = previous ? moment().subtract(14, 'months') : moment().subtract(12, 'months');
        const end = previous ? moment().subtract(12, 'months') : moment();
        return {
          startDate: start.add(1, 'month').startOf('month').format('YYYY-MM-DD'),
          endDate: end.endOf('month').format('YYYY-MM-DD'),
          interval: '1m',
        };
      }
      default:
        return getSettingsByPeriod('last_24_hours', tz);
    }
  }

  function parameterObjectToQuery(parameters) {
    const removeUndefined = _.pickBy(parameters, v => v !== undefined);
    const params = _.toPairs(removeUndefined).map(([param, value]) => {
      const val = Array.isArray(value) ? value.join(',') : value;
      return `${param}=${encodeURIComponent(val)}`;
    });
    return (params.length > 0) ? `?${params.join("&")}` : '';
  }

  function handleMissingEvents(devicePaired, deviceInstalled){
      if (!devicePaired){
        agent.add('Before I can answer that, you must first pair and install at least one Flo device.');
        agent.add(followUp);
      } else if (!deviceInstalled){
        agent.add('Before I can answer that, you must first install at least one Flo device.');
        agent.add(followUp);
      } else {
        fallback(agent);
      }
  }

  function welcome(agent) {
    agent.add(`Hello and welcome to Flo. You can learn about any alerts by asking if you have any pending alerts. Or if you want to know your home’s water usage, you can ask how much water you used today, yesterday, this week, this month, or this year.`);
  }

  function getEarliestDate(dates, fullDate = false){
    const earliest = dates.reduce((earliest, date) => !earliest || date < earliest ? date : earliest);
    if(!fullDate){
      return  moment.weekdays(moment(earliest).day());
    } else {
      return  moment(earliest).format('MMMM Do YYYY');
    }
  }

  function hasPairedAndInstalledDevices(allLocations) {
    // (null || undefined) means that is an enterprise account and we do not have the whole list of devices to avoid performance issues.
    if (!allLocations) {
      return {
        isPaired: true,
        isInstalled: true
      };
    }

    return {
      isPaired: _.some(allLocations, loc => !_.isEmpty((loc.devices || []).filter(d => d.deviceType === ProductType.SHUTOFF))),
      isInstalled: _.some(allLocations, loc => _.some((loc.devices || []).filter(d => d.deviceType === ProductType.SHUTOFF), dev => _.get(dev, 'installStatus.isInstalled', false))),
    };
  }

  function getTimezone(allLocations) {
    if (_.isEmpty(allLocations)) {
      return defaultTimezone;
    }

    return allLocations[0].timezone;
  }

  function getAllLocations(userData) {
    if (userData.account && userData.account.type === 'enterprise') {
      return Promise.resolve(null);
    }
    return axios.get(`users/${userData.id}/?expand=locations(devices)`)
      .then(userResponse => {
        return userResponse.data ? userResponse.data.locations : undefined;
      });
  }

  function handleConsumptionResult(data, period) {
    const gallons = data.aggregations ? Math.floor(data.aggregations.sumTotalGallonsConsumed) : 0;
    if (period === 'last_day') {
      if (gallons !== 1) {
        agent.add(`You have used ${gallons} gallons today!`);
        agent.add(followUp);
      } else{
        agent.add(`You have used ${gallons} gallon today!`);
        agent.add(followUp);
      }
    } else {
      const sinceDay = getEarliestDate(data.items.map(dataPoint=>dataPoint.time), period !== 'this_week');
      if (gallons !== 1) {
        agent.add(`Since ${sinceDay}, you have used ${gallons} gallons.`);
        agent.add(followUp);
      } else {
        agent.add(`Since ${sinceDay}, you have used ${gallons} gallon.`);
        agent.add(followUp);
      }
    }
  }

  function waterUsage(agent, period) {
    return  getUserInfo()
      .then(userData => {
        return Promise.all([
          userData,
          getAllLocations(userData)
        ]);
      })
      .then(([userData, allLocations]) => {
        return [
          hasPairedAndInstalledDevices(allLocations),
          userData,
          allLocations,
        ];
      })
      .then(([{isPaired, isInstalled}, userData, allLocations]) => {
        if (isPaired === false || isInstalled === false) {
          return handleMissingEvents(isPaired, isInstalled);
        }

        const timezone =  getTimezone(allLocations);
        const tz = timezone || defaultTimezone;
        const settings = getSettingsByPeriod(period, tz);
        const parameters = {
          startDate: settings.startDate,
          endDate: settings.endDate,
          interval: settings.interval,
          tz,
          userId: userData.id,
        };
        const query = parameterObjectToQuery(parameters);
        return axios.get(`water/consumption${query}`)
          .then(response => handleConsumptionResult(response.data, period));
      })
      .catch(error => {
        console.log(error);
        fallback(agent);
      });
  }

  function waterUsageToday(agent) {
    return waterUsage(agent, 'last_day');
  }

  function waterUsageThisWeek(agent) {
    return waterUsage(agent, 'this_week');
  }

  function waterUsageThisMonth(agent) {
    return waterUsage(agent, 'last_28_days');
  }

  function waterUsageThisYear(agent) {
    return waterUsage(agent, 'last_12_months');
  }

  function handleAlertResult(data) {
    if(data.total === undefined || data.total === 0) {
      agent.add(`Everything is fine at the moment. You have no alerts.`);
      agent.add(followUp);
    } else {
      const alertNames = getAllAlertsNames(data);
      if (alertNames.total < 2) {
        agent.add(`You have ${alertNames.total} pending alert. A ${alertNames.names}`);
        agent.add(followUp);
      } else {
        agent.add(`You have ${alertNames.total} pending alerts. A ${alertNames.names}`);
        agent.add(followUp);
      }
    }
  }

  function getAllAlertsNames(data) {
    const alertNames = data.items.map(event => event.displayTitle);
    if (alertNames.length === 1) {
      return { names: alertNames[0], total: 1 };
    }
    const alertNameListed = alertNames
      .slice(0, alertNames.length - 1)
      .join(', ')
      .concat([`, and ${ alertNames[alertNames.length - 1] }`]);
    return { names: alertNameListed, total: data.total };
  }

  function alertsOverview(agent) {
    return  getUserInfo()
      .then(userData => {
        return Promise.all([
          userData,
          getAllLocations(userData)
        ]);
      })
      .then(([userData, allLocations]) => {
        return [
          hasPairedAndInstalledDevices(allLocations),
          userData,
          allLocations,
        ];
      })
      .then(([{isPaired, isInstalled}, userData, allLocations]) => {
        if (isPaired === false || isInstalled === false) {
          return handleMissingEvents(isPaired, isInstalled);
        }

       return axios.get(`alerts?isInternalAlarm=false&userId=${userData.id}&status=triggered&severity=warning&severity=critical&page=1&size=25`)
          .then(response => handleAlertResult(response.data));
      })
      .catch(error => {
        console.log(error);
        fallback(agent);
      });
  }

  function fallback(agent) {
    agent.add(`Sorry, I didn’t catch that. You can always ask for help to see what I can do.`);
  }
  
  function yes(agent){
    agent.add(`You can always ask me any of the following:`);
    agent.add(`How much water have I used today, this week, this month, or this year? Also, you can ask: Do I have any alerts?`);
  }

  let intentMap = new Map();
  intentMap.set('Default Welcome Intent', welcome);
  intentMap.set('Default Fallback Intent', fallback);
  intentMap.set('Water Usage Today', waterUsageToday);
  intentMap.set('Water Usage This Week', waterUsageThisWeek);
  intentMap.set('Water Usage This Month', waterUsageThisMonth);
  intentMap.set('Water Usage This Year', waterUsageThisYear);
  intentMap.set('Yes', yes);
  //Alerts
  intentMap.set('Alerts Overview',alertsOverview);

  agent.handleRequest(intentMap);
});
