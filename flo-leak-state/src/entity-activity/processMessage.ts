import AWS from 'aws-sdk';
import config from '../config';
import { EntityActivityAction, EntityActivityMessage, EntityActivityType } from '../interfaces';

const isAlert = (msg: EntityActivityMessage): boolean => (msg.type === EntityActivityType.ALERT);

const isCreationOrUpdate = (msg: EntityActivityMessage): boolean => {
  return msg.action === EntityActivityAction.CREATED || msg.action === EntityActivityAction.UPDATED;
};

const isLeakRelatedAlert = (msg: EntityActivityMessage): boolean => {
  return config.leakRelatedAlarmIds.has(msg.item.alarm.id);
}

const processGoogleSmartHomeLeakState = async (msg: EntityActivityMessage): Promise<void> => {
  if (isAlert(msg) && isLeakRelatedAlert(msg) && isCreationOrUpdate(msg)) {
    console.log(`Invoking Lambda ${config.reportStateFunctionName} with payload ${JSON.stringify(msg)}`);
    await new AWS.Lambda().invoke({
      FunctionName: config.reportStateFunctionName,
      InvocationType: 'Event',
      Payload: JSON.stringify(msg)
    }).promise();
  }
}

const processIFTTTRealtimeAlert = async (msg: EntityActivityMessage): Promise<void> => {
  if (isAlert(msg) && isCreationOrUpdate(msg)) {
    console.log(`Invoking Lambda ${config.iftttAlertFunctionName} with payload ${JSON.stringify(msg)}`);
    await new AWS.Lambda().invoke({
      FunctionName: config.iftttAlertFunctionName,
      InvocationType: 'Event',
      Payload: JSON.stringify(msg)
    }).promise();
  }
}

export const processMessage = async (msg: EntityActivityMessage): Promise<void> => {
  await Promise.all([
    processGoogleSmartHomeLeakState(msg),
    processIFTTTRealtimeAlert(msg)
  ]);
}