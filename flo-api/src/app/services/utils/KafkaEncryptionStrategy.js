import EncryptionStrategy from './EncryptionStrategy';
import DIFactory from '../../../util/DIFactory';

class KafkaEncryptionStrategy extends EncryptionStrategy {

	constructor(keyId, config) {
		super(keyId, config);
	}
}

export default KafkaEncryptionStrategy;
