import axios from 'axios';
import config from '../config';

export const sendToDeviceStateService = async (macAddress: string): Promise<void> => {
  let fullUrl = `${config.fireWriterServiceBaseUrl}/v1/firestore/devices/${macAddress}`;
  let payload = {
    installStatus: {
      isInstalled: true
    }
  };

  await axios({
    method: 'post',
    url: fullUrl,
    headers: {
      'Content-Type': 'application/json'
    },
    data: payload
  });

  console.log(`POST ${fullUrl} Data: ${JSON.stringify(payload)}`);

}