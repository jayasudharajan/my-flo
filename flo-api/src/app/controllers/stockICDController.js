import container from '../../container';
import PairingService from '../services/pairing/PairingService';

const pairingService = container.get(PairingService);

/**
 * Retrieve StockICD details by QRCode data.
 */

export function retrieveByQrCode(req, res, next) {
  const { user_id } = req.params;
  const qrData = req.body;

  pairingService.scanQRCode(user_id, qrData)
    .then(result => res.json(result))
    .catch(next);
}