import { ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import MQTTCertService from './MQTTCertService';
import TMQTTCertConfig from './models/TMQTTCertConfig';

export const containerModule = new ContainerModule((bind, unbind, isBound) => {

  if (!isBound(TMQTTCertConfig)) {
    bind(TMQTTCertConfig).toConstantValue(TMQTTCertConfig({
      bucket: config.certBucket,
      clientCertificatePath: config.clientCertificatePath,
      clientKeyPath: config.clientKeyPath,
      caFilePath: config.mqttBroker.caFilePath,
      caV2FilePath: config.mqttBroker.caV2FilePath
    }));
  }

  bind(MQTTCertService).to(MQTTCertService);
});