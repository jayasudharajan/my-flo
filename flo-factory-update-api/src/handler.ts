import { APIGatewayEvent } from 'aws-lambda';
import axios from 'axios';
import * as E from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/pipeable';
import _ from 'lodash';
import config from './config';
import { 
  QrCodeDataCodec,
  QrCodeData,
  StockIcdCodec,
  StockIcd,
  RegistrationDataCodec,
  RegistrationData
} from './models';
import {
  InternalError,
  ValidationError,
  ForbiddenError,
  NotFoundError
} from './errors';

interface APIGatewayResponse {
  statusCode: number | string,
  headers?: Record<string, any>,
  body?: string,
  isBase64Encoded?: boolean
}

export const handler = async (event: APIGatewayEvent): Promise<APIGatewayResponse> => {
  try {
    const qrCodeData = validateQrData(event.body);
    const { ap_name, device_id }  = await scanQrCode(qrCodeData);
    const isPaired = await isDevicePaired(device_id);

    if (isPaired) {
      throw new ForbiddenError('Device is already paired.');      
    }

    const { ssh_private_key } = await getRegistrationData(device_id);

    return {
      statusCode: 200,
      body: JSON.stringify({
        ap_name,
        device_id,
        ssh_private_key
      })
    };

  } catch (err) {
    console.error(err);

    if (err instanceof InternalError) {
      const internalError = err as InternalError;

      return {
        statusCode: internalError.statusCode,
        body: JSON.stringify({
          message: internalError.message
        })
      };
    } 

    return {
      statusCode: 500,
      body: JSON.stringify(err.response ? err.response.data : {
        message: 'Something went wrong.'
      })
    };
  }
}

function validateQrData(data: string | null): QrCodeData {
  let parsedData: any;

  try {
    if (data) {
      parsedData = JSON.parse(data);
    } else {
      parsedData = null;
    }
  } catch {
    throw new ValidationError('Invalid QR code.');
  }

  return pipe(
    QrCodeDataCodec.decode(parsedData),
    E.getOrElse((): QrCodeData => { throw new ValidationError('Invalid QR code.'); })
  );

}

async function scanQrCode(qrCodeData: QrCodeData): Promise<StockIcd> {
  try {
    const response = await axios({
      method: 'POST',
      url: `${ config.apiUrl }/v1/stockicds/qrcode`,
      headers: {
        Authorization: config.apiToken
      },
      data: qrCodeData
    });

    return pipe(
      StockIcdCodec.decode(response.data),
      E.getOrElse((): StockIcd => { throw new Error('Invalid response.'); })
    );
  } catch (err) {
    if (err.response && err.response.status === 404) {
      throw new NotFoundError();
    }

    throw err;
  }
}

async function isDevicePaired(macAddress: string): Promise<boolean> {
  try {
    const response = await axios({
      method: 'GET',
      url: `${ config.apiUrl }/v2/devices`,
      headers: {
        Authorization: config.apiToken
      },
      params: {
        macAddress
      }
    });

    return response.status === 200 && !_.isEmpty(response.data);
  } catch (err) {

    if (err.response && err.response.status === 404) {
      return false;
    } 

    throw err;
  }
}

async function getRegistrationData(macAddress: string): Promise<RegistrationData> {
  try {
    const response = await axios({
      method: 'GET',
      url: `${ config.apiUrl }/v1/stockicds/registration/device/${ macAddress }`,
      headers: {
        Authorization: config.apiToken
      }
    });

    return pipe(
      RegistrationDataCodec.decode(response.data),
      E.getOrElse((): RegistrationData => { throw new Error('Invalid response.'); })
    );
  } catch (err) {
    
    if (err.response && err.response.status === 404) {
      throw new NotFoundError();
    }

    throw err;  
  }
}