import axios from 'axios';
import config from './config';

const apiBaseURI = `${config.gatewayUrl}/api/v2`;
const usersUrl = `${apiBaseURI}/users`;
const userAlertsUrl = `${apiBaseURI}/alerts/action`;
const alarmSettingsUrl = (userId: string) => `${usersUrl}/${userId}/alarmSettings`;
const getUserByIdUrl = (userId: string) => `${usersUrl}/${userId}?expand=locations`;

export default class GatewayService {
  public saveSettings(userId: string, settings: any): Promise<boolean> {
    return axios
      .post(alarmSettingsUrl(userId), settings)
      .then(() => true);
  }

  public getUserById(userId: string): Promise<any> {
    return axios
      .get(getUserByIdUrl(userId))
      .then(response => response.data);
  }

  public sendUserAction(action: any): Promise<any> {
    return axios
      .post(userAlertsUrl, action);
  }
}
