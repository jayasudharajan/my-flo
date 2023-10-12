import EncryptionStrategy from './EncryptionStrategy';
import DIFactory from '../../../util/DIFactory';

class DynamoEncryptionStrategy extends EncryptionStrategy {

	constructor(keyId, config) {
		super(keyId, config);
	}
}

export default DynamoEncryptionStrategy;
