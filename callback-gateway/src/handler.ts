import _ from 'lodash';
import { APIGatewayEvent, APIGatewayProxyResult } from 'aws-lambda';
import * as E from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/pipeable';
import axios from 'axios';
import qs from 'querystring';
import {
  CallbackParameters, CallbackParameterCodec, CallbackData
} from './models';
import {
  InternalError, ValidationError,
} from './errors';
import config from './config';

export const handler = async (event: APIGatewayEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('handler', event);
    const callbackData = new CallbackData(
      validateData(event.pathParameters),
      event.body,
      event.headers,
    );

    const responseData = await forwardCallback(callbackData);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8'
      },
      body: responseData
    };
  } catch (err) {
    console.error('handler', err);

    if (err instanceof InternalError) {
      const internalError = err as InternalError;

      return {
        statusCode: internalError.statusCode,
        body: JSON.stringify({
          message: internalError.message
        })
      };
    }

    return {
      statusCode: 500,
      body: JSON.stringify(err.response ? err.response.data : {
        message: 'Something went wrong.'
      })
    };
  }
}

function validateData(pathParameters: { [name: string]: string } | null): CallbackParameters {
  return pipe(
    CallbackParameterCodec.decode(pathParameters),
    E.getOrElse((): CallbackParameters => { throw new ValidationError('Invalid parameters.'); })
  );
}

async function forwardCallback(input: CallbackData, retryCount = 0): Promise<any> {
  try {
    console.log(`forwardCallback: Forwarding twilio callback, params: ${JSON.stringify(input.pathParameters)}, body: ${input.body}, retryCount: ${retryCount}`)

    const response = isUserInput(input) ?
      await forwardUserInput(input) :
      await forwardCallStatus(input);

    console.log(`forwardCallback: API callback successfully responded with data: ${response.data}, retryCount: ${retryCount}`);
    return response.data;
  } catch (err) {
    console.error(`forwardCallback: There was an error forwarding twilio voice callback, params: ${JSON.stringify(input.pathParameters)}, body: ${input.body}, retryCount: ${retryCount}`, err);
    if (err?.response?.status >= 400 && err?.response?.status < 500) {
      throw new InternalError(err?.response?.data?.message || 'Error', err?.response?.status, err?.response?.data);
    }

    if (retryCount < config.maxRetryCount) {
      await new Promise(resolve => setTimeout(resolve, config.retryIntervalMs));
      return forwardCallback(input, retryCount + 1);
    }

    throw err;
  }
}

function isUserInput(input: CallbackData): Boolean {
  return !_.isEmpty(qs.parse(input.body).Digits);
}

async function forwardUserInput(input: CallbackData): Promise<any> {
  console.log('forwardUserInput: forwarding user input');
  return axios({
    method: 'POST',
    url: `${config.apiUrl}/api/v1/voice/gather/user-action/${input.pathParameters.userId}/${input.pathParameters.incidentId}`,
    headers: {
      'Content-Type': input.getHeader('Content-Type'),
      'X-Twilio-Signature': input.getHeader('X-Twilio-Signature'),
    },
    data: input.body
  });
}

async function forwardCallStatus(input: CallbackData): Promise<any> {
  console.log('forwardCallStatus: forwarding call status');
  return axios({
    method: 'POST',
    url: `${config.apiUrl}/api/v2/delivery/hooks/voice/events/${input.pathParameters.incidentId}/${input.pathParameters.userId}`,
    headers: {
      'Content-Type': input.getHeader('Content-Type'),
      'X-Twilio-Signature': input.getHeader('X-Twilio-Signature'),
    },
    data: input.body
  });
}