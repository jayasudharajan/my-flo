class EmailClientMock {

	constructor() {
    this.sentEmails = [];
  }

	sendEmail(templateId, recipientAddress, data) {
		this.sentEmails.push({
			templateId,
      recipientAddress,
			data
		});

		return Promise.resolve(data);
	}

	getSentEmails() {
		return this.sentEmails;
	}

	clean() {
    this.sentEmails = [];
	}
}

module.exports = EmailClientMock;