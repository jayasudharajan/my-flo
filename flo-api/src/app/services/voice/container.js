import AWS from 'aws-sdk';
import axios from 'axios';
import { Container, ContainerModule } from "inversify";
import config from '../../../config/config';
import ICDAlarmIncidentRegistryLogTable from '../../models/ICDAlarmIncidentRegistryLogTable';
import ICDAlarmIncidentRegistryTable from '../../models/ICDAlarmIncidentRegistryTable';
import VoiceRouter from './routes';
import TwilioAuthMiddleware from './TwilioAuthMiddleware';
import TwilioVoiceRequestLogTable from './TwilioVoiceRequestLogTable';
import VoiceController from './VoiceController';
import VoiceService from './VoiceService';
import VoiceServiceConfig from './VoiceServiceConfig';

// Declare bindings
const container = new Container();

const dynamoDbOptions = {
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion,
  httpOptions: {
    timeout: config.aws.timeoutMs
  }
};

const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbOptions);

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  if (!isBound('HttpClient')) {
    bind('HttpClient').toConstantValue(axios);
  }

  if (!isBound('ApiHost')) {
    bind('ApiHost').toConstantValue(config.apiHost);
  }

  if (!isBound('VoiceGatherActionUrl')) {
    bind('VoiceGatherActionUrl').toConstantValue(config.voiceGatherActionUrl);
  }
});

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(TwilioAuthMiddleware).toConstantValue(new TwilioAuthMiddleware(config));
container.bind(VoiceServiceConfig).toConstantValue(new VoiceServiceConfig(config));
container.bind(ICDAlarmIncidentRegistryTable).toConstantValue(new ICDAlarmIncidentRegistryTable());
container.bind(ICDAlarmIncidentRegistryLogTable).toConstantValue(new ICDAlarmIncidentRegistryLogTable());

container.bind(TwilioVoiceRequestLogTable).to(TwilioVoiceRequestLogTable)
container.bind(VoiceService).to(VoiceService);
container.bind(VoiceController).to(VoiceController);
container.bind(VoiceRouter).to(VoiceRouter);
container.load(containerModule);

export default container;