import StockICDService from './StockICDService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class StockICDController extends CrudController {

  constructor(stockICDService) {
    super(stockICDService.stockIcdTable);
    this.stockICDService = stockICDService;
  }

  /**
   * Request a QR Code an Client Certificate from the Flo PKI Service
   */
  generateStockICD(req, res, next) {
    const body = req.body;

    return this.stockICDService.generateStockICD(
         body.device_id,
         body.wlan_mac_id,
         {
           ssid: body.wifi_ssid,
           password: body.wifi_password
         },
         body.sku,
         {
           key: body.websocket_key,
           cert: body.websocket_cert
         },
         body.icd_login_token,
         body.ssh_private_key
       );
  }

  removeFromPki(req, res, next) {
    const body = req.body;
    
    return this.stockICDService.removeFromPki(
      body.id,
      body.device_id
    );
  }

  /**
   * Retrieve the QR Code of a specific device.
   */
  retrieveQrCode(req, res, next) {
    const { id } = req.params;

    return this.stockICDService.retrieveQrCodeByDeviceId(id);
  }

  retrieveQrCodeByDeviceId(req, res, next) {
    const { device_id } = req.params;

    return this.stockICDService.retrieveQrCodeByDeviceId(device_id);
  }

  retrieveQrDataByDeviceId(req, res, next) {
    const { device_id } = req.params;

    return this.stockICDService.retrieveQrDataByDeviceId(device_id);
  }

  retrieveRegistrationByDeviceId(req, res, next) {
    const { device_id } = req.params;

    return this.stockICDService.retrieveRegistrationByDeviceId(device_id);
  }

  /**
   * Retrieve the websocket login token of a specific device.
   */
  retrieveWebSocketTokenByDeviceId(req, res, next) {
    const { device_id } = req.params;

    return this.stockICDService.retrieveWebSocketTokenByDeviceId(device_id);
  }

  generateSerialNumber({ body: data }) {

    return this.stockICDService.generateSerialNumber(data);
  }

  removeSerialNumberBySN({ params: { sn } }) {

    return this.stockICDService.removeSerialNumberBySN(sn);
  }

  removeSerialNumberByDeviceId({ query: { device_id } }) {

    return this.stockICDService.removeSerialNumberByDeviceId(device_id);
  }

  retrieveSerialNumberBySN({ params: { sn } }) {

    return this.stockICDService.retrieveSerialNumberBySN(sn);
  }

  retrieveSerialNumberByDeviceId({ query: { device_id } }) {

    return this.stockICDService.retrieveSerialNumberByDeviceId(device_id);
  }
}

export default new DIFactory(new ControllerWrapper(StockICDController), [ StockICDService ]);