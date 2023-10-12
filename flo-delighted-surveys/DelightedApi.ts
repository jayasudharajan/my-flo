import axios from 'axios';
import _ from 'lodash';
import moment from 'moment';
import config from './config';
import { UserInfo } from './interfaces';

class DelightedApi {
  constructor(
    private delighted: any,
  ) {}

  public async createPerson(userInfo: UserInfo, eventDate: string): Promise<void> {
    try {
      const nextSurveySchedule = await this.retrieveNextSurveySchedule(userInfo);
      const surveyTargetDate = nextSurveySchedule || moment.utc(eventDate).clone().add(config.surveyInitialDelay, 'seconds');
      const delay = Math.max(0, surveyTargetDate.diff(moment.utc(), 'seconds'));

      const payload = {
        email: userInfo.email,
        name: `${userInfo.firstName} ${userInfo.lastName}`,
        delay: delay,
        properties: {
          subscriber: `${userInfo.isFloProtectSubscriber}`
        }
      };

      console.log(`Deleting potentially pending surveys for email ${userInfo.email}}`);
      this.deletePendingSurveys(userInfo.email);

      console.log(`Creating/Updating person in Delighted with payload: ${JSON.stringify(payload)}`);
      await this.delighted.person.create(payload);
    } catch (err) {
      console.error(`Error while creating/updating person in Delighted with email ${userInfo.email}: ${JSON.stringify(err)}`);
      Promise.resolve();
    }
  }

  private async deletePendingSurveys(email: string): Promise<void> {
    try {
      await this.delighted.surveyRequest.deletePending({ person_email: email });
    } catch (err) {
      if (err.message && err.message.status !== 404) {
        console.warn(`Error while deleting pending surveys for email ${email} => ${JSON.stringify(err)}`);
      }
    }
  }

  private async retrieveNextSurveySchedule(userInfo: UserInfo): Promise<moment.Moment | null> {
    try {
      const response = await axios.request({
        method: 'GET',
        url: `${config.delightedApiBaseUrl}/people.json?email=${userInfo.email}`,
        auth: {
          username: config.delightedApiKey,
          password: ''
        }
      });

      const nextSurveySchedule = response.data.next_survey_scheduled_at;
      if (_.isNil(nextSurveySchedule)) {
        return null;
      }
      return moment.unix(nextSurveySchedule).utc();
    } catch (err) {
      console.warn(`Error while retrieving next survey schedule for email ${userInfo.email} => ${JSON.stringify(err)}`);
      return null;
    }
  }
}

export default DelightedApi;