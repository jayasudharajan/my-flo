export default class CustomerEmailSubscriptionRouteMap {
  constructor() {

    this.retrieve = {
      get: '/subscription/:user_id'
    };

    this.updateSubscriptions = {
      put: '/subscription/:user_id'
    };

    this.retrieveAllEmails = {
      get: '/'
    };
  }
}