const UserInfoIntentHandler = require('./UserInfoIntentHandler');
const _ = require('lodash');

class PendingAlertIntentHandler extends UserInfoIntentHandler {

  constructor(...args) {
    super(...args);
    this.authorizationResource = 'alerts';
  }
  
  retrieveInfo({ user, accessToken }) {

    return this._makeRequest({
      method: 'get',
      url: `${ this.url }/v2/alerts?isInternalAlarm=false&userId=${user.id}&status=triggered`,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })
    .then(response => {
      const { total, items } = response.data;

      if (!total) {
        return 'Everything is fine at the moment. You have no alerts.';
      }

      const alertNames = _.chain(items)
        .uniqBy('displayTitle')
        .map('displayTitle')
        .value();

      if (alertNames.length === 1) {
        return `You have ${ alertNames.length } pending alert: A ${ alertNames[0] }`;
      } else {
        const alertNameListed = alertNames
        .slice(0, alertNames.length - 1)
        .join(', ')
        .concat([`, and ${ alertNames[alertNames.length - 1] }`]);

        return `You have ${ alertNames.length } pending alerts: A ${ alertNameListed }`;
      }

    });
  }
}

exports.PendingAlertIntentHandler = PendingAlertIntentHandler;