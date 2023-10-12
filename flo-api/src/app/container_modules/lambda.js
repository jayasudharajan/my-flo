import AWS from 'aws-sdk';
import EncryptionStrategy from '../services/utils/EncryptionStrategy';
import config from '../../config/config';
import { ContainerModule } from 'inversify';

export default new ContainerModule(bind => {
  bind(AWS.Lambda).toConstantValue(new AWS.Lambda({
    region: config.aws.dynamodb.region
  }));
});