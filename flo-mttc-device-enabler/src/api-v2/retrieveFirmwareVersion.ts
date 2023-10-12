import axios, { AxiosRequestConfig } from 'axios';
import config from '../config';

const retrieveFirmwareVersion = async (icdId: string): Promise<string | null | undefined> => {
  const request: AxiosRequestConfig = {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: config.apiAccessToken
    },
    url: `${config.apiV2BaseUrl}${config.apiV2DevicesPath}/${icdId}`
  };
  const response = await axios(request);

  return response.data.fwVersion;
}

export default retrieveFirmwareVersion;
