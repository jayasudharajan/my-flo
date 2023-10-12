import { Pinpoint } from 'aws-sdk';
import moment from 'moment';
import _ from 'lodash';
import { EventData } from './interfaces';

const EVENT_NAME = 'learning.mode.complete';
const APP_TITLE = 'flo-out-of-learning-notifications';

class PinpointApi {
  constructor(
    private pinpoint: Pinpoint,
    private pinpointAppId: string | undefined
  ) {
    if (_.isEmpty(pinpointAppId)) {
      throw Error('Parameter pinpointAppId is required');
    }
  }

  public async sendEvent(eventData: EventData) {
    try {
      const createdAt = moment(eventData.eventCreatedAt).toISOString();

      const params: Pinpoint.Types.PutEventsRequest = {
        ApplicationId: this.pinpointAppId as string,
        EventsRequest: {
          BatchItem: {
            [eventData.awsEndpointId]: {
              Endpoint: {
                User: {
                  UserId: eventData.userId
                }
              },
              Events: {
                OutOfLearning: {
                  EventType: EVENT_NAME,
                  AppTitle: APP_TITLE,
                  Timestamp: createdAt,
                  Attributes: {
                    FirstName: eventData.firstName,
                    LastName: eventData.lastName,
                    Email: eventData.email
                  },
                },
              }
            },
          }
        }
      };

      const res = await this.pinpoint.putEvents(params).promise();
      console.log('Event successfully sent to Pinpoint', res);
      return Promise.resolve();
    } catch (err) {
      console.error('Error trying to send event to Pinpoint', err);
      return Promise.reject(err);
    }
  }
}

export default PinpointApi;