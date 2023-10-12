const axios = require('axios');

const axiosRetry = require('axios-retry'); //SEE: https://stackoverflow.com/questions/56074531/how-to-retry-5xx-requests-using-axios
axiosRetry(axios, {
    retries: 1, // once is ok & safe enough for now, consider carefully before bumping
    retryDelay: (retryCount) => {
        console.debug(`axiosRetry attempt: ${retryCount}`);
        const retryMs = parseInt(process.env.HTTP_RETRY_SLEEP_MS) || 222;
        return retryMs > 0 ? retryMs : 222; //linear decay
    },
    retryCondition: (error) => {
        switch (error?.response?.status || 0) {
            case 502:
            case 503:
                console.warn('axiosRetry: AFTER ', error);
                return true;
            default: //don't retry by default
                return false;
        }
    },
});

const apiUrl = process.env.FLO_API_URL ?? 'https://api-gw-dev.flocloud.co';
const smartHomeUrl = process.env.FLO_ALEXA_SMARTHOME_URL ?? 'https://flo-alexa-smarthome.flocloud.co'
const applicationId = process.env.APPLICATION_ID;

const waterConsumption = require('./waterConsumption');
const alerts = require('./alerts');
const builtin = require('./builtin');
const custom = require('./custom');

const intentHandlerMap = {
	GetWaterConsumptionToday: event => 
		new waterConsumption.WaterConsumptionTodayIntentHandler(axios, apiUrl).handleEvent(event),
	GetWaterConsumptionThisMonth: event =>
		new waterConsumption.WaterConsumptionThisMonthIntentHandler(axios, apiUrl).handleEvent(event),
	GetWaterConsumptionThisWeek: event =>
		new waterConsumption.WaterConsumptionThisWeekIntentHandler(axios, apiUrl).handleEvent(event),
	GetWaterConsumptionLastTwelveMonths: event => 
		new waterConsumption.WaterConsumptionLast12MonthsIntentHandler(axios, apiUrl).handleEvent(event),
	GetPendingAlerts: event =>
		new alerts.PendingAlertIntentHandler(axios, apiUrl).handleEvent(event),
	'AMAZON.HelpIntent': event =>
		new builtin.HelpIntentHandler().handleEvent(event),
	'AMAZON.StopIntent': event =>
		new builtin.StopIntentHandler().handleEvent(event),
	'AMAZON.CancelIntent': event => 
		new builtin.StopIntentHandler().handleEvent(event),
	'AMAZON.NavigateHomeIntent': event =>
		new builtin.SessionEndedRequestHandler().handleEvent(event),
		//new builtin.StopIntentHandler().handleEvent(event),
	'AMAZON.YesIntent': event => {
		const helpIntentHandler = new builtin.HelpIntentHandler();
		const yesIntentHandler = new builtin.ContextAwareIntentHandler(helpIntentHandler);
		const waterConsumptionThisWeekIntentHandler = new waterConsumption.WaterConsumptionThisWeekIntentHandler(axios, apiUrl);

		yesIntentHandler.addContextHandler('help', waterConsumptionThisWeekIntentHandler);
		return yesIntentHandler.handleEvent(event);
	},
	'AMAZON.NoIntent': event => {
		const helpIntentHandler = new builtin.HelpIntentHandler();
		const noIntentHandler = new builtin.ContextAwareIntentHandler(helpIntentHandler);
		const stopIntentHandler = new builtin.StopIntentHandler();

		noIntentHandler.addContextHandler('help', stopIntentHandler);
		return noIntentHandler.handleEvent(event);
	}
};

exports.handler = (event, context) => {
	try {
		inputLog(event);

		const ns = event?.directive?.header?.namespace;
		if(ns) {
			const nsRe = /^(Alexa|Flo)/i;
			if(nsRe.test(ns) && (event.directive.header.name || '').length > 0) { //Alexa SmartHome directive request
				return new custom.DirectiveHandler(axios, smartHomeUrl).handleEvent(event)
					.then(resp => successHandler(context, resp))
					.catch(err => errorHandler(context, err));
			} else {
				const e = new custom.DirectiveConstructionError(event, new custom.DomainError('Bad namespace or missing action name', 400));
				errorHandler(context, e);
			}
		}

		const PING_REQUEST = 'PingRequest';
		let appId = '';
		if(event.session && event.session.application && event.session.application.applicationId) {
			appId = event.session.application.applicationId;
		}
		const type = event.request ? event.request.type : '';
		if (applicationId !== appId) {
			if (type !== PING_REQUEST) { //allow ping through w/o application Id
				if(appId) {
					return errorHandler(context, new custom.DomainError(`Invalid application ID ${ appId }`, 400));
				} else {
					return errorHandler(context, new custom.DomainError(`Missing application ID or Bad input format.`, 400));
				}
			}
		}

		switch (type) {
			// Launch request
			case 'LaunchRequest':
				new builtin.LaunchRequestHandler().handleEvent(event)
					.then(response => successHandler(context, response))
					.catch(err => errorHandler(context, err));
				break;
			// Intent request
			case 'IntentRequest':
				handleIntent(event)
					.then(response => successHandler(context, response))
					.catch(err => errorHandler(context, err));
				break;
			case 'SessionEndedRequest':
				new builtin.SessionEndedRequestHandler().handleEvent(event)
					.then(response => successHandler(context, response))
					.catch(err => errorHandler(context, err));
				break;
			case PING_REQUEST:
				new custom.PingHandler(axios, smartHomeUrl, applicationId).handleEvent(event)
					.then(response => successHandler(context, response))
					.catch(err => errorHandler(context, err));
				break;
			default: 
				new builtin.UnknownRequestHandler().handleEvent(event)
					.then(response => successHandler(context, response))
					.catch(err => errorHandler(context, err));
				break;
		}
	} catch (err) {
		context.fail(err);
	}
};

function inputLog(evt) {
	console.debug('input:', evt);
}

function successHandler(ctx, resp) {
	console.info('response:', resp)
	ctx.succeed(resp);
}

function errorHandler(ctx, err) {
	console.error('error:', err)
	ctx.fail(err);
}

function handleIntent(event) {
    const intentName = event.request && event.request.intent ? event.request.intent.name : '';
    const intention = intentHandlerMap[intentName];
	if (!intention) {
		return Promise.reject(new Error(`Invalid intent ${ intentName }`));
	}
	return intention(event);
}



