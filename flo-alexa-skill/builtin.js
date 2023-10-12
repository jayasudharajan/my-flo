const RequestHandler = require('./RequestHandler');

class HelpIntentHandler extends RequestHandler {
  constructor() {
    super();
  }

  handleEvent(event) {
    const responseText = `
      You can learn about any alerts by asking if you have any pending alerts.
      Or if you want to know your home’s water usage, you can ask how much water you used today, this week, this month, or this year.
      Would you like to know how much water you have used this week?
    `;
    const speechResponse = this.createSpeechletResponse(responseText);
    const rePromptText = `Would you like to know how much water you have used this week?`;
    const responseData = this.createResponse(
      Object.assign(
        {},
        speechResponse,
        { 
          shouldEndSession: false,
          reprompt: this.createSpeechletResponse(rePromptText)
        }
      ),
      {
        context: 'help'
      }
    );

    return Promise.resolve(responseData);
  }
}

class StopIntentHandler extends RequestHandler {

  constructor() {
    super();
  }

  handleEvent(event) {
    const responseText = 'Goodbye';

    return Promise.resolve(
      this.createResponse(
        this.createSpeechletResponse(responseText)
      )
    );
  }
}

class ContextAwareIntentHandler extends RequestHandler {

  constructor(noContextHandler) {
    super();

    this.contextHandlers = {};
    this.noContextHandler = noContextHandler;
  }

  handleEvent(event) {
    const context = (event.session.attributes || {}).context;
    const contextHandler = this.contextHandlers[context];

    if (contextHandler) {
      return contextHandler.handleEvent(event);
    }

    return this.noContextHandler.handleEvent(event);
  }

  addContextHandler(context, handler) {
    this.contextHandlers[context] = handler;
  }
}

class LaunchRequestHandler extends RequestHandler {
  constructor() {
    super();
  }

  handleEvent(event) {
    const responseText = `
      Hello and welcome to Flo.
      
      You can learn about any alerts by asking if you have any pending alerts.
      Or if you want to know your home’s water usage, you can ask how much water you used today, this week, this month, or this year.
    `;
    const speechResponse = this.createSpeechletResponse(responseText);
    const responseData = this.createResponse(Object.assign(
      {},
      speechResponse,
      {
        reprompt: speechResponse,
        shouldEndSession: false
      }
    ));

    return Promise.resolve(responseData);
  }
}

class SessionEndedRequestHandler extends RequestHandler {
  constructor() {
    super();
  }

  handleEvent(event) {
    const response = this.createResponse({ shouldEndSession: true });

    return Promise.resolve(response);
  }
}

class UnknownRequestHandler extends RequestHandler {
  constructor() {
    super();
  }

  handleEvent(event) {
    const response = this.createResponse(this.createSpeechletResponse('Goodbye'));

    return Promise.resolve(response);
  }
}

exports.HelpIntentHandler = HelpIntentHandler;
exports.StopIntentHandler = StopIntentHandler;
exports.ContextAwareIntentHandler = ContextAwareIntentHandler;
exports.LaunchRequestHandler = LaunchRequestHandler;
exports.SessionEndedRequestHandler = SessionEndedRequestHandler;
exports.UnknownRequestHandler = UnknownRequestHandler;