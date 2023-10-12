import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';
import CustomerEmailSubscriptionService from './CustomerEmailSubscriptionService';

class CustomerEmailSubscriptionController {
  constructor(customerEmailSubscriptionService) {
    this.customerEmailSubscriptionService = customerEmailSubscriptionService;
  }

  retrieve({ params: { user_id } }) {
    return this.customerEmailSubscriptionService.retrieve(user_id);
  }

  updateSubscriptions({ params: { user_id, email_id }, body: subscriptions }) {
    return this.customerEmailSubscriptionService.updateSubscriptions(user_id, subscriptions);
  }

  retrieveAllEmails() {
    return this.customerEmailSubscriptionService.retrieveAllEmails();
  }
}

export default new DIFactory(new ControllerWrapper(CustomerEmailSubscriptionController), [CustomerEmailSubscriptionService]);