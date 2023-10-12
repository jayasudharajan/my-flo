import DIFactory from  '../../../util/DIFactory';
import KafkaProducer from '../utils/KafkaProducer';
import ICDService from '../icd-v1_5/ICDService';
import DirectiveService from '../directives/DirectiveService';
import TaskSchedulerService from '../task-scheduler/TaskSchedulerService';
import ICDForcedSystemModeTable from './ICDForcedSystemModeTable';
import DeviceInForcedSleepException from './models/exceptions/DeviceInForcedSleepException';
import moment from 'moment';
import uuid from 'node-uuid';

class DeviceSystemModeService {
  constructor(icdService, directiveService, taskSchedulerService, kafkaProducer, icdForcedSystemModeTable) {
    this.icdService = icdService;
    this.directiveService = directiveService;
    this.taskSchedulerService = taskSchedulerService;
    this.kafkaProducer = kafkaProducer;
    this.icdForcedSystemModeTable = icdForcedSystemModeTable;
  }

  isInForcedSleep(icdId) {

    return this.icdForcedSystemModeTable.retrieveLatestByIcdId(icdId)
      .then(({ Items }) => Items.some(({ system_mode }) => system_mode));
  }

  rejectIfInForcedSleep(icdId) {

    return this.isInForcedSleep(icdId)
      .then(isInForcedSleep => {
        if (isInForcedSleep) {
          return Promise.reject(new DeviceInForcedSleepException());
        } 
      });
  }

  scheduleWakeUp(icdId, deviceId, wakeUpTime, directiveTopic, wakeUpSystemMode = 2) {
    const delayedDirectiveMessage = this.directiveService.createDirectiveMessage(
      'set-system-mode',
      icdId,
      deviceId,
      {
        mode: wakeUpSystemMode
      }
    );

    return Promise.all([
      this.kafkaProducer.encrypt(JSON.stringify(delayedDirectiveMessage)),
      this.directiveService.getDirectivesKafkaTopic()
    ])
    .then(([encryptedDelayedDirectiveMessage, directiveTopic]) =>
      this.taskSchedulerService.schedule(
        wakeUpTime,
        directiveTopic,
        encryptedDelayedDirectiveMessage,
        `sleep:${icdId}:${uuid.v4()}`,
        {
          ...delayedDirectiveMessage,
          task_type: 'sleep'
        }
      )
    );
  }

  cancelScheduledWakeUp(icdId) {    
    return this.taskSchedulerService.cancelTasksByIcdId(icdId, 'sleep');
  }

  sleep(icdId, wakeUpSystemMode, sleepMinutes, metadata) {

    return this.rejectIfInForcedSleep(icdId)
      .then(() => Promise.all([
        this.icdService.retrieve(icdId),
        this.directiveService.getDirectivesKafkaTopic()
      ]))
      .then(([{ Item: { device_id } }, directiveTopic]) => Promise.all([
        this._sendSetSystemModeDirective(icdId, 5, { ...metadata, wakeUpSystemMode, sleepMinutes }),
        this.scheduleWakeUp(
          icdId,
          device_id,
          moment().add(sleepMinutes, 'minutes'),
          directiveTopic,
          wakeUpSystemMode
        )
      ]))
      .then(() => true); 
  }

  enableForcedSleep(icdId, metadata) {
    return Promise.all([
      this._sendSetSystemModeDirective(icdId, 5, metadata),
      this.cancelScheduledWakeUp(icdId),
      this.icdForcedSystemModeTable.create({
        icd_id: icdId,
        system_mode: 5,
        performed_by_user_id: metadata.user_id
      })
    ]).then(() => true);
  }

  disableForcedSleep(icdId, metadata) {

    return Promise.all([
      this.cancelScheduledWakeUp(icdId),
      this.icdForcedSystemModeTable.create({
        icd_id: icdId,
        system_mode: null,
        performed_by_user_id: metadata.user_id
      })
    ]).then(() => true);
  }

  _mapSystemModeName(systemMode) {
    return systemMode == 2 ?
      'home' :
      systemMode == 3 ?
        'away' :
        systemMode == 5 ?
          'sleep' :
          'home';
  }

  _sendSetSystemModeDirective(icdId, systemMode, metadata) {
    const systemModeName = this._mapSystemModeName(systemMode);
    const sleepModeData = systemModeName != 'sleep' || metadata.sleepMinutes === undefined ?
      {} : 
      {
        revert_minutes: metadata.sleepMinutes,
        revert_mode: this._mapSystemModeName(metadata.wakeUpSystemMode),
        revert_scheduled_at: moment().add(metadata.sleepMinutes, 'minutes').toISOString()
      };

    return this.icdService.patch(icdId, { target_system_mode: systemModeName, ...sleepModeData })
      .then(() => 
        this.directiveService.sendDirective(
          'set-system-mode',
          icdId,
          metadata.user_id,
          metadata.app_used,
          { mode: systemMode }
        )
      );
  }

  setSystemMode(icdId, systemMode, metadata) {
    return this.rejectIfInForcedSleep(icdId)
      .then(() => Promise.all([
        this.icdService.retrieve(icdId),
        this._sendSetSystemModeDirective(icdId, systemMode, metadata),
        this.cancelScheduledWakeUp(icdId)
      ]))
      .then(() => true);
  }

}

export default new DIFactory(DeviceSystemModeService, [ICDService, DirectiveService, TaskSchedulerService, KafkaProducer, ICDForcedSystemModeTable]);