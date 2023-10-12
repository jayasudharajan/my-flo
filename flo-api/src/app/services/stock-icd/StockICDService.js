import _ from 'lodash';
import uuid from 'node-uuid';
import qr from '../../../util/qrCodeUtil';
import DIFactory from  '../../../util/DIFactory';
import NotFoundException from '../utils/exceptions/NotFoundException';
import ServiceException from '../utils/exceptions/ServiceException';
import ConflictException from '../utils/exceptions/ConflictException';
import TooManyRequestsException from '../utils/exceptions/TooManyRequestsException';
import TStockICDKafkaMessage from './models/TStockICDKafkaMessage';
import TRemoveStockICDKafkaMessage from './models/TRemoveStockICDKafkaMessage';
import StockICDTable from './StockICDTable';
import DeviceSerialNumberTable from './DeviceSerialNumberTable';
import DeviceSerialNumberCounterTable from './DeviceSerialNumberCounterTable';
import KafkaProducer from '../utils/KafkaProducer';
import AWS from 'aws-sdk';
import S3Utils from '../utils/S3Utils';
import config from '../../../config/config';
import moment from 'moment';

class StockICDService {

  constructor(stockIcdTable, deviceSerialNumberTable, deviceSerialNumberCounterTable, kafkaProducer, s3, dynamoDbClient) {
    this.stockIcdTable = stockIcdTable;
    this.deviceSerialNumberTable = deviceSerialNumberTable;
    this.deviceSerialNumberCounterTable = deviceSerialNumberCounterTable;
    this.kafkaProducer = kafkaProducer;
    this.s3 = s3;
    this.s3Utils = new S3Utils(s3);
    this.dynamoDbClient = dynamoDbClient;
  }

  /**
   * Generate a stock ICD entry that allow the icd be paired
   */
  generateStockICD(device_id, wlan_mac_id, wifi_data, sku, websocket_data, icd_login_token, ssh_private_key) {

    return this.stockIcdTable.retrieveByDeviceId({device_id})
      .then(({Items}) => {

        if (Items && Items.length) {
          return {
            id: Items[0].id
          };
        } else {
          const message = TStockICDKafkaMessage.create({
            id: uuid.v4().replace(/-/g, '').toUpperCase(),
            icd_uuid: uuid.v4().replace(/-/g, '').toUpperCase(),
            pairing_code: uuid.v4(),
            requested_at: new Date().toISOString(),
            device_id: device_id,
            wlan_mac_id: wlan_mac_id,
            wifi_ssid: wifi_data.ssid,
            wifi_password: wifi_data.password,
            sku: sku,
            websocket_key: websocket_data.key,
            websocket_cert: websocket_data.cert,
            icd_login_token: icd_login_token,
            ssh_private_key: ssh_private_key,
            generation_version: config.pkiGenerationVersion
          });

          const result = {
            id: message.id
          };

          return this.kafkaProducer.send(config.pkiKafkaTopic, JSON.stringify(message), false, device_id)
            .then(() => result);
        }
      });
  }

  removeFromPki(id, deviceId) {
    return this.retrieve(id)
      .then(stockIcdEntry => {
        const device_id = deviceId.toLowerCase();

        if (stockIcdEntry.device_id != device_id) {
          return Promise.reject(new ServiceException('Stock ICD id and device id do not belong to the same entry.'));
        }

        const message = TRemoveStockICDKafkaMessage.create({
          id,
          device_id
        });

        return this.kafkaProducer
          .send(config.pkiRemoveDeviceKafkaTopic, JSON.stringify(message))
          .then(() => { id });
      });
  }

  /**
   * Retrieve the QR Code of a specific device.
   */
  retrieveQrCode(id) {

    return this.stockIcdTable.retrieve({id})
      .then(result => {
        if (_.isEmpty(result)) {
          return new Promise((resolve, reject) => reject(new NotFoundException('Item not found.')));
        } else {
          const qrCode = {
            qr_code_data_png: result.Item.qr_code_data_png
          };
          return qrCode;
        }
      });
  }

  retrieveQrCodeByDeviceId(device_id) {
    return this.stockIcdTable.retrieveByDeviceId({device_id})
      .then(({Items}) => {
        if (!Items || !Items.length) {
          return new Promise((resolve, reject) => reject(new NotFoundException('QR code not found.')));
        }

        return this.s3Utils.retrieveFile(
          config.qrCodesBucket,
          `${config.qrCodesPathTemplate.replace('@ID', Items[0].id)}${device_id}.svg`
        ).then(data => ({ qr_code_data_svg: data.toString('utf8') }));
      });
  }

  retrieveQrDataByDeviceId(device_id) {

    return this.stockIcdTable.retrieveByDeviceId({device_id})
      .then(({Items}) => {
        if (!Items || !Items.length) {
          return Promise.reject(new NotFoundException('QR data not found.'));
        }

        const [{id: i, icd_uuid: e}] = Items;

        return `V:2$I:${i}$E:${e}$`;
      });
  }

  /**
   * Retrieve the websocket login token of a specific device.
   */
  retrieveWebSocketTokenByDeviceId(device_id) {

    return this.stockIcdTable.retrieveByDeviceId({device_id})
      .then(({Items}) => {
        if (Items && Items.length) {
          return {
            new_device: false,
            websocket_token: Items[0].icd_login_token,
            websocket_tls_enabled: true    // we may need to check if TLS certs exist.. need a better logic
          };
        } else {
          return {
            new_device: true,
            websocket_token: config.floDeviceDefaultWebsocketToken,
            websocket_tls_enabled: false    // we may need to check if TLS certs exist.. need a better logic
          };
        }
      });
  }


  retrieveRegistrationByDeviceId(device_id) {

    return this.stockIcdTable.retrieveByDeviceId({device_id})
      .then(({Items}) => {
        if (!Items || !Items.length) {
          return Promise.reject(new NotFoundException('Registration not found.'));
        }

        const {
          wlan_mac_id,
          device_id,
          wifi_password,
          wifi_ssid,
          sku,
          icd_websocket_cert: websocket_cert,
          icd_websocket_key: websocket_key,
          icd_login_token,
          ssh_private_key
        } = Items[0];

        return {
          wlan_mac_id,
          device_id,
          wifi_password,
          wifi_ssid,
          sku,
          websocket_cert,
          websocket_key,
          icd_login_token,
          ssh_private_key
        };
      });
  }

  /**
   * Create one stockICD.
   */
  create(stockIcdItem) {

    return this.stockIcdTable.create(stockIcdItem);
  }

  /**
   * Retrieve one stockICD.
   */
  retrieve(id) {

    return this.stockIcdTable.retrieve({id})
      .then(result => {
        if (_.isEmpty(result)) {
          return new Promise((resolve, reject) => reject(new NotFoundException('Item not found.')));
        } else {
          return result.Item;
        }
      });
  }

  /**
   * Update one item.  (replace)
   */
  update(id, data) {
    data.id = id;

    return this.stockIcdTable.update(data);
  }

  /**
   * Patch one stockICD.  Use this to update individual fields.
   */
  patch(id, data) {

    return this.stockIcdTable.patch({id}, data);
  }

  /**
   * Delete one stockICD.
   */
  remove(id) {

    return this.stockIcdTable.remove({id})
      .then(result => {
        if (!result) {
          return new Promise((resolve, reject) => reject(new NotFoundException('Item not found.')));
        } else {
          return result;
        }
      });
  }

  /**
   * Archive ('delete') one stockICD.
   */
  archive(id) {

    return this.stockIcdTable.archive({id})
      .then(result => {
        if (!result) {
          return new Promise((resolve, reject) => reject(new NotFoundException('Item not found.')));
        } else {
          return result;
        }
      });
  }

  retrieveByDeviceId(deviceId) {

    return this.stockIcdTable.retrieveByDeviceId({ device_id: deviceId })
      .then(({ Items: [stockICD] }) => stockICD);
  }

  _calculateSerialNumberCheckSum(serialNumber) {
    const charCodeA = 65; // => 'A'.charCodeAt(0) 
    const charCodeRange = 25 // => 'Z'.charCodeAt(0) - 'A'.charCodeAt(0)
    let sum = 0;

    for (let i = 0; i < serialNumber.length; i++) {
      sum += serialNumber.charCodeAt(i);
    }

    return String.fromCharCode(sum % charCodeRange + charCodeA);
  }

  _formatSerialNumber(product, date, dailyCounter, site, valve, pcba) {
    // https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/741474308/Serial+Number
    const charCodeA = 65; // => 'A'.charCodeAt(0) 
    const yearChar = String.fromCharCode(
      charCodeA + 
      moment(date).diff('2019-01-01T00:00:00.000Z', 'years')
    );
    const dayOfYear = ('00' + moment(date).dayOfYear()).slice(-3);
    const formattedDailyCounter = ('00' + dailyCounter.toString(16)).slice(-3);
    const serialNumberWithoutCheckDigit = [
      product,
      yearChar,
      dayOfYear,
      formattedDailyCounter,
      site,
      valve,
      pcba
    ].join('');
    const checkSum = this._calculateSerialNumberCheckSum(serialNumberWithoutCheckDigit);

    return (serialNumberWithoutCheckDigit + checkSum).toUpperCase();
  }

  _commitSerialNumber(date, generateSN) {
    let cancellationReaonsPromise = Promise.resolve([]);

    return this.deviceSerialNumberCounterTable.retrieveAndIncrement(date)
      .then(({ Attributes: { counter: dailyCounter } }) => {
        const serialNumberData = generateSN(dailyCounter);

        // Counter portion of the Serial Number is a 3 digit hex value 
        if (dailyCounter >= 0xFFF) {
          return Promise.reject(new ServiceException('Max counter value exceeded.'));
        }

        return this.deviceSerialNumberTable.createUnique(serialNumberData)
          .then(() => serialNumberData);
      })
      .catch(err => {
        if (err.name === 'ConditionalCheckFailedException') {
          return Promise.reject(new ConflictException('Serial number already exists.'));
        } else {
          return Promise.reject(err);
        } 
      });
  }

  generateSerialNumber(data) {
    const { 
      device_id,
      site,
      valve,
      pcba,
      product
    } = data;
    const now = moment().toISOString();
    const date = moment(now).utc().startOf('day');
    const dateISOString = date.toISOString();

    return this._commitSerialNumber(dateISOString, dailyCounter => {
      const serialNumber = this._formatSerialNumber(product, dateISOString, dailyCounter, site, valve, pcba);

      return {
        device_id: device_id.toLowerCase(),
        year: date.year(),
        day_of_year: date.dayOfYear(),
        site: site.toUpperCase(),
        valve: valve.toUpperCase(),
        pcba: pcba.toUpperCase(),
        product: product.toUpperCase(),
        sn: serialNumber,
        created_at: now
      };
    });
  }

  removeSerialNumberBySN(serialNumber) {

    return this.retrieveSerialNumberBySN(serialNumber)
      .then(serialNumberData => {
          return this.removeSerialNumberByDeviceId(serialNumberData.device_id);
      });
  }

  removeSerialNumberByDeviceId(deviceId) {
    return this.deviceSerialNumberTable.remove(deviceId.toLowerCase()) 
      .catch(err => {
        if (err.name == 'ConditionalCheckFailedException') {
          return Promise.reject(new NotFoundException('Serial number not found.'));
        } else {
          return Promise.reject(err);
        }
      });
  }

  retrieveSerialNumberByDeviceId(deviceId) {
    return this.deviceSerialNumberTable.retrieve(deviceId.toLowerCase())
      .then(({ Item }) => {
        if (!Item) {
          return {
            items: []
          };
        } 
        const { created_at, ...data } = Item;

        return {
          items: [data]
        };
      });
  }

  retrieveSerialNumberBySN(serialNumber) {
    return this.deviceSerialNumberTable.retrieveBySerialNumber(serialNumber.toUpperCase())
      .then(({ Items }) => {

        if (!Items.length || !Items[0]) {
          return Promise.reject(new NotFoundException('Serial number not found.'));
        }

        return Items[0];
      });
  }
}

export default new DIFactory(StockICDService, [StockICDTable, DeviceSerialNumberTable, DeviceSerialNumberCounterTable, KafkaProducer, AWS.S3, AWS.DynamoDB.DocumentClient]);
