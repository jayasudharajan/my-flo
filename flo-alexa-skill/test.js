const { handler } = require('./index');

const context = {
  fail: err => console.error('FAIL', err),
  succeed: response => console.log('SUCCEED', JSON.stringify(response)),
}

const event = {
  request: {
    type: 'IntentRequest',
    intent: {
      name: 'GetWaterConsumptionThisMonth'
    },
  },
  session: {
    application: {
      applicationId: process.env.APPLICATION_ID
    },
    user: {
      accessToken: process.env.ACCESS_TOKEN
    }
  }
}

handler(event, context);
