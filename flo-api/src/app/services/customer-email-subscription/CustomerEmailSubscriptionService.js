import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import CustomerEmailSubscriptionTable from './CustomerEmailSubscriptionTable';
import CustomerEmailTable from './CustomerEmailTable';
import DIFactory from  '../../../util/DIFactory';

class CustomerEmailSubscriptionService {
  constructor(customerEmailSubscriptionTable, customerEmailTable) {
    this.customerEmailSubscriptionTable = customerEmailSubscriptionTable;
    this.customerEmailTable = customerEmailTable;
  }

  retrieve(userId) {
    return this.customerEmailSubscriptionTable.retrieve(userId)
      .then(({ Item = {} }) => Item);
  }

  updateSubscriptions(userId, subscriptions) {
    return this.customerEmailSubscriptionTable.updateSubscriptions(userId, subscriptions);
  }

  retrieveAllEmails() {
    return this.customerEmailTable.retrieveAll()
      .then(({ Items }) => ({ data: Items }));
  }
}

export default new DIFactory(CustomerEmailSubscriptionService, [CustomerEmailSubscriptionTable, CustomerEmailTable]);
