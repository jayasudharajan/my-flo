import DIFactory from  '../../../util/DIFactory';
import KafkaProducer from '../utils/KafkaProducer';
import TDirectiveMQTTMessage from './models/TDirectiveMQTTMessage';
import TDirectiveKafkaMessage from './models/TDirectiveKafkaMessage';
import DirectiveConfig from './DirectiveConfig';
import NotFoundException from '../utils/exceptions/NotFoundException';
import DirectiveLogTable from '../../models/DirectiveLogTable';
import ICDService from '../icd-v1_5/ICDService';
import { directiveDataMap } from './models/directiveData';

class DirectiveService {

  constructor(directiveConfig, directiveLogTable, icdService, kafkaProducer) {
    this.icdService = icdService;
    this.kafkaProducer = kafkaProducer;
    this.directiveLogTable = directiveLogTable;
    this.directiveConfig = directiveConfig;
  }

  retrieveDirectiveLogByDirectiveId(directiveId) {
    return this.directiveLogTable.retrieveByDirectiveId(directiveId);
  }

  _createDirectiveLog({
                       icd_id,
                       created_at = new Date().toISOString(),
                       directive,
                       directive_type,
                       status = 1,
                       user_id,
                       directive_id,
                       app_used
                     }) {
    return {
      icd_id,
      created_at,
      directive,
      directive_type,
      status,
      user_id,
      directive_id,
      app_used
    };
  }

  getDirectivesKafkaTopic() {
    return this.directiveConfig.getDirectivesKafkaTopic();
  }

  createDirectiveMessage(directive, icdId, deviceId, data) {
    const dataSchemaValidator = directiveDataMap[directive];
    const validatedDataWithType = dataSchemaValidator(data);

    const mqttMsg = TDirectiveMQTTMessage.create({
      directive,
      device_id: deviceId,
      data: validatedDataWithType
    });
    const kafkaMsg = TDirectiveKafkaMessage.create({
      icd_id: icdId,
      directive: mqttMsg
    });

    return kafkaMsg;
  }

  sendDirective(directive, icd_id, user_id, app_used, data) {

    return Promise.all([
      this.getDirectivesKafkaTopic(),
      this.icdService.retrieve(icd_id)
    ]).then( ([ directivesTopic, { Item: icd } ]) => {
      if (!icd) {
        return Promise.reject(new NotFoundException('Device not found.'));
      }

      const kafkaMsg = this.createDirectiveMessage(directive, icd_id, icd.device_id, data);

      const logData = this._createDirectiveLog({
        icd_id,
        user_id,
        directive_type: directive,
        directive_id: kafkaMsg.directive.id,
        directive: JSON.stringify(kafkaMsg.directive),
        app_used: app_used
      });

      return Promise.all([
        this.kafkaProducer.send(directivesTopic, JSON.stringify(kafkaMsg), false, icd.device_id),
        this.directiveLogTable.create(logData)
      ]);
    });
  }
}

export default new DIFactory(DirectiveService, [ DirectiveConfig, DirectiveLogTable, ICDService, KafkaProducer ]);


