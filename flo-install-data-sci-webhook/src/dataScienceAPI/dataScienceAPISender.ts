import axios from 'axios';
import uuid from 'uuid';
import config from '../config';

export async function sendToDataScienceAPI(macAddress: string, installDate: string): Promise<void> {
  let fullUrl = `${config.dataScienceApiUrl}`;
  let payload = {
    message_id: uuid.v4(),
    devices: [
      {
        device_id: macAddress,
        installation_date: installDate
      }
    ]
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