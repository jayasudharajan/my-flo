import PairingService from './PairingService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class PairingController {
  constructor(pairingService) {
    this.pairingService = pairingService;
  }

  scanQRCode({ token_metadata: { user_id }, body: qrContents }) {
    return this.pairingService.scanQRCode(user_id, qrContents);
  }

  retrievePairingDataByICDId({ params: { icd_id } }) {
    return this.pairingService.retrievePairingDataByICDId(icd_id);
  }

  unpairDevice({ params: { icd_id } }) {
    return this.pairingService.unpairDevice(icd_id);
  }

  initPairing({ token_metadata: { user_id }, body: { data: qr } }) {
    return this.pairingService.initPairing(user_id, qr);
  }

  completePairing({ app_used, token_metadata: { user_id }, params: { icd_id }, body: { device_id, timezone } }) {
    return this.pairingService.completePairing(icd_id, device_id, timezone, user_id, app_used)
      .then(() => ({}));
  }
}

export default new DIFactory(new ControllerWrapper(PairingController), [PairingService]);