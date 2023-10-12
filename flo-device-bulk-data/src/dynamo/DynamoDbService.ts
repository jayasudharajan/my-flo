import _ from 'lodash';
import DynamoDbClient from './DynamoDbClient';
import { StockICD } from '../model/interfaces';

class DynamoDbService {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async getPrivateKeyByMacAddress(macAddress: string): Promise<StockICD | null> {
    try {

      const stockICD = _.first(await this.dynamoDbClient.query<StockICD>('StockICD', {
        IndexName: 'DeviceId',
        KeyConditionExpression: 'device_id = :device_id',
        ExpressionAttributeValues: {
          ':device_id': macAddress
        }
      }));

      if (!stockICD) {
        console.log(`StockICD with macAddress ${macAddress} not found.`);
        return null;
      }

      return stockICD
    } catch (err) {
      console.log(`An error ocurred trying to retrieve private key for macAddress: ${macAddress}`, err);
      return null;
    }
  }
}

export default DynamoDbService;