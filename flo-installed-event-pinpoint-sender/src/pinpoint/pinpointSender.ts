import {Pinpoint} from 'aws-sdk';
import moment from 'moment';
import config from '../config';
import {EventData} from '../interfaces';
import generateInstalledPushMessage from './generateInstalledPushMessage';

const pinpoint = new Pinpoint({ apiVersion: config.pinpointVersion });

export const sendEventToPinpoint = async (eventData: EventData): Promise<void> => {
  const createdAt = moment(eventData.createdAt).toISOString();
  const event: Pinpoint.Types.PutEventsRequest = {
    ApplicationId: config.pinpointAppId as string,
    EventsRequest: {
      BatchItem: {
        [eventData.awsEndpointId]: {
          Endpoint: {
            User: {
              UserId: eventData.userId
            }
          },
          Events: {
            [config.pinpointEventType]: {
              EventType: config.pinpointEventType,
              AppTitle: config.pinpointAppTitle,
              Timestamp: createdAt,
              Attributes: {
                FirstName: eventData.firstName,
                LastName: eventData.lastName,
                Email: eventData.email
              }
            }
          }
        }
      }
    }
  };
  console.log(`Sending event to Pinpoint => ${JSON.stringify(event)}`);
  const response = await pinpoint.putEvents(event).promise();
  console.log(`Received response from Pinpoint => ${JSON.stringify(response)}`);

  console.log(`Sending push for device installed to Pinpoint => ${JSON.stringify(event)}`);
  const pushResponse = await sendInstalledPush(eventData);
  console.log(`Received response from Pinpoint about the push => ${JSON.stringify(pushResponse)}`);
};

async function sendInstalledPush(eventData: EventData): Promise<Pinpoint.Types.SendMessagesResponse | void> {
  const message = generateInstalledPushMessage(eventData);
  if(message) {
    const params: Pinpoint.Types.SendMessagesRequest = {
      ApplicationId: config.pinpointAppId as string,
      MessageRequest: message
    };

    return await pinpoint.sendMessages(params).promise();
  }

  return Promise.resolve();
}


