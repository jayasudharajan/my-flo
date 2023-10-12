import { ContainerModule } from 'inversify';
import AWS from 'aws-sdk';
import config from '../../config/config';

export default new ContainerModule(bind => {
  const s3 = new AWS.S3({
    region: config.aws.region,
    apiVersion: '2006-03-01'
  });

  bind(AWS.S3).toConstantValue(s3);
});