import SubResourceProvider from './SubResourceProvider';
import DIFactory from  '../../../../util/DIFactory';
import UserAccountService from '../../user-account/UserAccountService';
import LocationService from '../../location-v1_5/LocationService';

class AccountProvider extends SubResourceProvider {
  constructor(userAccountService, locationService) {
    super('Account');
    this.userAccountService = userAccountService;
    this.locationService = locationService;
  }

  retrieveByAccountId({ account_id }) {
    return Promise.resolve(this.formatSubResource(account_id));
  }

  retrieveByUserId({ user_id }) {
    return (
      user_id ? 
        this.userAccountService.retrieveAccountIdByUserId(user_id) :
        Promise.resolve()
     )
     .then(accountId => this.formatSubResource(accountId));
  }

  retrieveByLocationId({ location_id }) {
    return (
      location_id ?
        this.locationService.retrieveByLocationId(location_id) :
        Promise.resolve({ Items: [] })
    )
    .then(({ Items: [location] }) => {

      return this.formatSubResource(location && location.account_id)
    });
  }
}

export default new DIFactory(AccountProvider, [UserAccountService, LocationService]);
