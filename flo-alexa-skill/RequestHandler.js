
class RequestHandler {
  createResponse(response, sessionAttributes = {}) {
    return {
      version: '1.0',
      sessionAttributes,
      response: Object.assign(
        { shouldEndSession: true },
        response
      )
    };
  }

  createSpeechletResponse(text) {
    return {
      outputSpeech: {
        type: 'PlainText',
        text
      }
    };
  }
}

module.exports = RequestHandler;