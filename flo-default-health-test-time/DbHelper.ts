import _ from 'lodash';
import moment from 'moment';
import DynamoDbClient from './DynamoDbClient';
import { Icd, Location, OnboardingEvent, OnboardingLog } from './interfaces';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async getDeviceRecord(icdId: string): Promise<Icd | null> {
    return this.dynamoDbClient.get('ICD', { id: icdId });
  }

  public async getLocationByLocationId(locationId: string): Promise<Location | null> {
    const locations = await this.dynamoDbClient.query<Location>('Location', {
      IndexName: 'LocationIdIndex',
      KeyConditionExpression: 'location_id = :location_id',
      ExpressionAttributeValues: {
        ':location_id': locationId
      }
    });

    return locations[0] || null;
  }

  public async isFirstInstalledEvent(log: OnboardingLog): Promise<boolean> {
    return Promise.resolve(
      log.event >= OnboardingEvent.INSTALLED &&
        this.noPreviousInstalledEvent(log.icd_id, log.created_at)
    );
  }

  private async noPreviousInstalledEvent(icdId: string, installedEventDate: string): Promise<boolean> {
    const logs = await this.dynamoDbClient.query<OnboardingLog>('OnboardingLog', {
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': icdId
      }
    });

    return _.isEmpty(_.find(logs, (log) =>
      log.event >= OnboardingEvent.INSTALLED &&
        moment(log.created_at).isBefore(moment(installedEventDate))
    ));
  }
}

export default DbHelper;