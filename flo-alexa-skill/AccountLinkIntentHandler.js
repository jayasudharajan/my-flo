const RequestHandler = require('./RequestHandler');

class AccountLinkIntentHandler extends RequestHandler {

  handleEvent(event) {
    const accessToken = event.session.user.accessToken;

    if (!accessToken) {
      return Promise.resolve(this.createAccountLinkResponse());
    }

    return this.handleIntent(event)
      .then(responseText => 
        this.createResponse(
          this.createSpeechletResponse(responseText)
        )
      )
      .catch(err => {
        if (err.response && err.response.status === 401) {
          return Promise.resolve(this.createAccountLinkResponse());
        } else if (err.response && err.response.status === 403) {
          return Promise.resolve(this.createUnauthorizedResponse());
        } else {
          return Promise.reject(err);
        }
      });
  }

  handleIntent(event) {
    return Promise.reject(new Error('Not implemented.'));
  }

  createAccountLinkResponse(message) {
    const responseText = [
      'Before I can answer that, you first need to link your Flo account',
      'by going to the Home section of your Alexa app and selecting "Link Account"',
      'on the "Account Setup" card delivered by Flo.'
    ]
    .join(' ');

    return this.createResponse(
      Object.assign(
        {},
        this.createSpeechletResponse(message || responseText),
        {
          shouldEndSession: true,
          card: {
            type: 'LinkAccount'
          }
        }
      )
    );
  }

  createUnauthorizedResponse() {
    const responseText = `Before I can answer that, you first need to grant permission to access
      your ${ this.authorizationResource } by going to the Home section of your Alexa app and selecting 
      "Link Account" on the "Account Setup" card delivered by Flo.`;

    return this.createAccountLinkResponse(responseText);
  }
}

module.exports = AccountLinkIntentHandler;