import 'source-map-support/register';
import {APIGatewayProxyEvent, APIGatewayProxyResult, Handler} from 'aws-lambda';
import type {ValidatedEventAPIGatewayProxyEvent} from '@libs/api-gateway';
import {middyfy} from '@libs/lambda';

import schema from './ping-schema';
import ResponseModel from "@libs/response.model";
import {envOrDefault, envOrThrow, scrubDirtyFields, tryConvJson} from "@libs/utils";
import {AlexaService, IAlexaService} from "@libs/services/alexa.service";
import ValidationError from "@libs/validation.error";
import {PingLevel, PingService} from "@libs/services/ping.service";

const pingHandler: ValidatedEventAPIGatewayProxyEvent<typeof schema> = async (event) => {
  let depth = PingLevel.Unknown;
  let target:string|undefined = undefined;
  if(event?.httpMethod === 'POST' || (event?.headers && event.headers["Content-Type"] == 'application/json')) {
    const tp = tryConvJson(event?.body ?? {});
    depth = tp.itemB && tp.itemA.deep === true ? PingLevel.Deep : PingLevel.Shallow;
    if(tp.itemB && typeof(tp.itemA.target === 'string')) {
      target = tp.itemA.target as string;
    }
  }
  const pinger = new PingService(depth === PingLevel.Unknown ? undefined : getAlexa());
  const resp = await pinger.ping(depth, target);
  return ResponseModel.Content(resp, resp.status === 'OK' ? 200 : 503);
}

let _alexa :IAlexaService; //lazy singleton
function getAlexa() :IAlexaService {
  if(!_alexa) {
    const fn = envOrThrow('ALEXA_LAMBDA');
    _alexa = new AlexaService(fn);
  }
  return _alexa;
}

const relayHandler: Handler<APIGatewayProxyEvent> = async (event): Promise<APIGatewayProxyResult> => {
  const bt = typeof(event?.body);
  if(event && bt === 'object') {
    try {
      const req = event.body as any;
      const alexa = getAlexa();
      const resp = await alexa.invoke(req);
      const addHead = {
        "lambda-relay-version":resp.ExecutedVersion ?? 'unknown',
        "lambda-relay-region":envOrDefault('REGION', 'unknown'),
      };
      console.info('relay-handle', JSON.stringify(scrubDirtyFields(req)), '=>', JSON.stringify(scrubDirtyFields(resp)));
      return ResponseModel.Content(resp.Payload, resp.StatusCode, addHead);
    } catch (e) {
      return ResponseModel.ErrorCatcher(e, 'relay-handle-error');
    }
  } else {
    const e = new ValidationError(`Invalid event.body type: ${bt}`, event).setNote('relay-handle-bad-type');
    console.warn('relay-handle-type-error', JSON.stringify(scrubDirtyFields(e)));
    return ResponseModel.Error(e);
  }
}

export const ping = middyfy(pingHandler);
export const relay = middyfy(relayHandler);
