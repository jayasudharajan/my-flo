const _ = require('lodash');
const AccountLinkIntentHandler = require('./AccountLinkIntentHandler');
const defaultTimezone = 'Etc/UTC';
const ProductType = {
  DETECTOR: 'puck_oem',
  SHUTOFF: 'flo_device_v2'
};

class UserInfoIntentHandler extends AccountLinkIntentHandler {
  
  constructor(axios, url) {
    super();
    this.axios = axios;
    this.url = url;
  }

  _makeRequest(options) {
    return this.axios(options)
      .then(response => {
        if (response.status !== 200) {
          // TODO Error
          return Promise.reject(new Error());
        }

        return response;
      });
  }

  getUser(accessToken) {
    return this._makeRequest({
      method: 'get',
      url: `${ this.url }/v2/users/me?expand=account`,
      headers: {
        Authorization: `Bearer ${ accessToken }`
      }
    })
    .then(response => {
      if(response.data !== '' && response.data.id !== undefined && response.data.id !== "") {
        return response.data;
      } else {
        return Promise.reject('Unable to find user data');
      }
    });
  }

  getAllLocations(accessToken, userData) {
    if (userData.account && userData.account.type === 'enterprise') {
      return Promise.resolve(null);
    }
    return this._makeRequest({
      method: 'get',
      url: `${this.url}/v2/users/me?expand=locations(devices)`,
      headers: {
        Authorization: `Bearer ${ accessToken }`
      }
    })
    .then(userResponse => {
      return userResponse.data ? userResponse.data.locations : undefined;
    });
  }

  getTimezone(allLocations) {
    if (_.isEmpty(allLocations)) {
      return defaultTimezone;
    }

    return allLocations[0].timezone;
  }

  hasPairedAndInstalledDevices(allLocations) {
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

  ensureHasDeviceInstalled(user, devicePaired, deviceInstalled) {
    if (user.account.type === 'enterprise') {
      return { user };
    }

    if (!devicePaired) {
      return {
        response: 'Before I can answer that, you must first pair and install at least one Flo device.'
      }
    } else if (!deviceInstalled) {
      return {
        response: 'Before I can answer that, you must first install at least one Flo device.'
      }
    }
    return { user };
  }

  handleIntent(event) {
    const accessToken = event.session.user.accessToken;

    return this.getUser(accessToken)
      .then(user => {
        return Promise.all([
          user,
          this.getAllLocations(accessToken, user)
        ]);
      })
      .then(([userData, allLocations]) => {
        return [
          this.hasPairedAndInstalledDevices(allLocations),
          userData,
          allLocations,
        ];
      })
      .then(([{isPaired, isInstalled}, user, allLocations]) => {
        return {
          ...this.ensureHasDeviceInstalled(user, isPaired, isInstalled),
          timezone: this.getTimezone(allLocations),
        }
      })
      .then(({ user, response, timezone }) => {
        return response || this.retrieveInfo({ user, accessToken, timezone });
      });
  }

  // Should be overridden
  retrieveInfo(data) {
    return Promise.reject(new Error('Not implemented.'));
  } 
}

module.exports = UserInfoIntentHandler;