import { Device } from '../interfaces';
import DynamoDbClient from './dynamo/DynamoDbClient';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async retrieveDeviceInfo(icdId: string): Promise<Device | null> {
    try {
      const icd = await this.dynamoDbClient.get<Device>('ICD', { id: icdId });
      if (icd === null) {
        console.log(`Device with ID ${icdId} not found.`);
        return null;
      }
      return icd;
    } catch (err) {
      console.error('An error occurred trying to retrieve Device info.', err);
      return null;
    }
  }
}

export default DbHelper;