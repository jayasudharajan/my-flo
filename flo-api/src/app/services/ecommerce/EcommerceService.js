import DIFactory from  '../../../util/DIFactory';
import EmailClient from '../utils/EmailClient'
import EcommerceServiceConfig from './EcommerceServiceConfig';

class EcommerceService {

	constructor(config, emailClient) {
		this.emailClient = emailClient;
		this.config = config;
	}

  handleOrderPaymentCompleted(email, data) {
    return this
			.config
			.getOrderPaymentCompletedEmailTemplateId()
			.then(templateId => this.emailClient.sendEmail(templateId, email, data));
	}
}

export default new DIFactory(EcommerceService, [ EcommerceServiceConfig, EmailClient ]);