import APIV1Service from './APIV1Service';
import GatewayService from './GatewayService';
import SystemMode from './constants/SystemMode';
import _ from 'lodash';

const deliveryMediums = {
  EMAIL: 2,
  PUSH_NOTIFICATION: 3,
  SMS: 4,
  VOICE: 5
};

const deprecatedAlarmIds = [25, 24];

export default class UserAlarmSettingsMigrationService {
  constructor(
    private apiV1Service: APIV1Service,
    private gatewayService: GatewayService,
  ) {}

  public async migrate(userId: string): Promise<boolean> {
    const user = await this.gatewayService.getUserById(userId);
    const deviceId = _.get(user, 'locations[0].devices[0].id');
    const locationId = _.get(user, 'locations[0].id');
    const v1Settings = await this.apiV1Service.getCombinedPreferences(userId, locationId);
    const leakSensitivity = await this.apiV1Service.getLeakSensitivity(v1Settings);
    const v2Settings = this.adaptV1SettingsToV2(deviceId, this.filterByDeprecatedAlarms(v1Settings), leakSensitivity);

    return this.gatewayService.saveSettings(userId, v2Settings);
  }

  private filterByDeprecatedAlarms(v1Settings: any): any {
    return v1Settings.filter((setting: any) => !deprecatedAlarmIds.includes(setting.alarm_id));
  }

  private adaptV1SettingsToV2(deviceId: string, oldSettings: any, leakSensitivity: number): any {
    const settings = oldSettings.filter((x: any) => x.alarm_id != 12).map((oldSetting: any) => {
      const enabledMediums = oldSetting.is_user_overwritable ? oldSetting.optional : oldSetting.mandatory;

      return {
        alarmId: oldSetting.alarm_id,
        systemMode: SystemMode.fromId(oldSetting.system_mode).name,
        emailEnabled: _.includes(enabledMediums, deliveryMediums.EMAIL),
        pushEnabled: _.includes(enabledMediums, deliveryMediums.PUSH_NOTIFICATION),
        smsEnabled: _.includes(enabledMediums, deliveryMediums.SMS),
        callEnabled: _.includes(enabledMediums, deliveryMediums.VOICE)
      }
    });

    const newHotWaterAlarm = settings.filter((x: any) => x.alarmId == 14).map((x:any) => ({
      ...x,
      alarmId: 12
    }));

    return {
      items: [{
        deviceId: deviceId,
        smallDripSensitivity: leakSensitivity,
        settings: _.concat(settings, newHotWaterAlarm)
      }]
    };
  }
}
