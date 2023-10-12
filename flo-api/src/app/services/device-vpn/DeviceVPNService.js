import DIFactory from  '../../../util/DIFactory';
import moment from 'moment';
import uuid from 'node-uuid';
import VPNWhitelistTable from './VPNWhitelistTable';
import DirectiveService from '../directives/DirectiveService';
import ICDService from '../icd-v1_5/ICDService';
import TaskSchedulerService from '../task-scheduler/TaskSchedulerService';
import NotFoundException from "../utils/exceptions/NotFoundException";

class DeviceVPNService {

  constructor(vpnWhitelistTable, icdService, directiveService, taskSchedulerService) {
    this.vpnWhitelistTable = vpnWhitelistTable;
    this.icdService = icdService;
    this.directiveService = directiveService;
    this.taskSchedulerService = taskSchedulerService;
  }

  enable(deviceId, userId, appUsed) {
    return Promise.all([
      this.icdService.retrieveByDeviceId(deviceId),
      this.vpnWhitelistTable.retrieve(deviceId),
      this.directiveService.getDirectivesKafkaTopic()
    ]).then(([{ Items: icds }, { Item: vpnWhitelistEntry }, directiveTopic]) => {
      const start = Math.ceil(moment().valueOf() / 1000);
      const endDateTime = moment().add(30, 'minutes');
      const end = Math.ceil(endDateTime.valueOf() / 1000);
      const basicInfo = {
        start: start,
        end: end
      };

      if (!icds.length) {
        return Promise.resolve(new NotFoundException("Device not found."))
      }

      const icdId = icds[0].id;

      if (!vpnWhitelistEntry) {
        return this
          .vpnWhitelistTable
          .create({
            ...basicInfo,
            device_id: deviceId
          });
      }

      const enableVPNDirectiveData = {
        enabled: true
      };

      const disableVPNDirectiveMessage = this.directiveService.createDirectiveMessage(
        'update-vpn-configuration',
        icdId,
        deviceId,
        {
          enabled: false
        }
      );

      return Promise.all([
        this
          .vpnWhitelistTable
          .patch({ device_id: deviceId }, basicInfo),
        this
          .directiveService
          .sendDirective('update-vpn-configuration', icdId, userId, appUsed, enableVPNDirectiveData),
        this
          .taskSchedulerService
          .schedule(endDateTime, directiveTopic, disableVPNDirectiveMessage, `disable-vpn:${deviceId}:${uuid.v4()}`, {})
      ]).then(([result]) => ({ device_id: deviceId, ...result.Attributes }));
    });
  }

  disable(deviceId, userId, appUsed) {
    return this
      .icdService
      .retrieveByDeviceId(deviceId)
      .then(({ Items: icds }) => {

        if (!icds.length) {
          return Promise.resolve(new NotFoundException("Device not found."))
        }

        const icdId = icds[0].id;

        const disableVPNDirectiveData = {
          enabled: false
        };

        return Promise.all([
          this.vpnWhitelistTable.remove(deviceId),
          this.directiveService.sendDirective('update-vpn-configuration', icdId, userId, appUsed, disableVPNDirectiveData)
        ]).then(([result]) => result);
      });
  }

  retrieveVPNConfig(deviceId) {
    return this
      .vpnWhitelistTable
      .retrieve(deviceId)
      .then(({ Item: data }) => {
        if (!data) {
          return Promise.resolve({
            vpn_enabled: false
          });
        }

        return Promise.resolve({
          ...data,
          vpn_enabled: true
        });
      });
  }
}


export default new DIFactory(DeviceVPNService, [VPNWhitelistTable, ICDService, DirectiveService, TaskSchedulerService]);