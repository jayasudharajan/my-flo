import axios, { AxiosRequestConfig, AxiosResponse } from 'axios';
import moment from 'moment';
import config from '../config';
import { Device, OnboardingEvent } from '../interfaces';

const minDate = moment().subtract(config.mttcMinDays, 'days').toISOString();
const deviceFilter = {
  filter: {
    '[onboarding.event]': {
      gte: OnboardingEvent.INSTALLED
    },
    '[onboarding.created_at]': {
      lte: minDate
    }
  }
};

interface DeviceResponse {
  items: Device[],
  scrollId?: string
}

const retrieveDevices = async (scrollId?: string): Promise<AxiosResponse<DeviceResponse>> => {
  const request: AxiosRequestConfig = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: config.apiAccessToken
    },
    url: `${config.apiV1BaseUrl}${config.apiV1DevicesPath}/scroll`
  };

  if (!scrollId) {
    request.url += `?scroll_ttl=${config.deviceScrollTtl}&size=${config.deviceScrollSize}`;
    request.data = deviceFilter;
  } else {
    request.url += `/${scrollId}?scroll_ttl=${config.deviceScrollTtl}`;
  }

  return axios(request);
}

const scrollThruDevices = async (fn: ((devices: Device[]) => Promise<void>), optScrollId?: string): Promise<void> => {
  const { data: { items, scrollId }} = await retrieveDevices(optScrollId);

  await Promise.all<any>([
    items.length && fn(items),
    items.length && scrollId && scrollThruDevices(fn, scrollId)
  ]);
}

export default scrollThruDevices;
