import config from '../config';
import axios from 'axios';
import UserAlarmSettingsMigrationService from "../UserAlarmSettingsMigrationService";
import APIV1Service from "../APIV1Service";
import GatewayService from "../GatewayService";

axios.defaults.headers.common['Authorization'] = config.apiToken;

const migrationService = new UserAlarmSettingsMigrationService(new APIV1Service(), new GatewayService());

export const handleUserAlarmNotificationDeliveryRule = async (userDeliveryRule: any): Promise<void> => {
  const userId = userDeliveryRule.user_id;

  console.log(`Migrating alarm settings got user ${userId}.`);

  return migrationService.migrate(userId)
    .catch(console.error)
    .then(() => {});
};
