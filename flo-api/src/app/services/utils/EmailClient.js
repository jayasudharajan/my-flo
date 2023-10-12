import sendwithus from 'sendwithus';

export default class EmailClient {
	constructor(emailProviderConfig) {
		this.emailProviderConfig = emailProviderConfig;
	}

	sendEmail(emailTemplateId, recipientAddress, data) {
		return Promise.all([
			this.emailProviderConfig.getApiKey(),
			this.emailProviderConfig.getSenderAddress(),
			this.emailProviderConfig.getSenderName()
		])
		.then(([ apiKey, senderAddress, senderName ]) => {
			const options = {
				email_id: emailTemplateId,
				recipient: {
					address: recipientAddress
				},
				email_data: data,
				sender: {
					address: senderAddress,
					name: senderName
				}
			};
			const deferredEmail = Promise.defer();

			sendwithus(apiKey).send(options, (err, response) => {
				if (err) {
					deferredEmail.reject(apiKey);
				} else {
					deferredEmail.resolve(response);
				}
			});

			return deferredEmail.promise;
		});
	}
}