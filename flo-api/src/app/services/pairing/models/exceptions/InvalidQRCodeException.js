import ServiceException from '../../../utils/exceptions/ServiceException'

export default class InvalidQRCodeException extends ServiceException {
  constructor() {
    super('Invalid QR code.');
    this.status = 400;
  }
}