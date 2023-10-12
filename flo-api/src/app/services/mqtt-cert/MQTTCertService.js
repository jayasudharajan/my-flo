import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import TMQTTCertConfig from './models/TMQTTCertConfig';

class MQTTCertService {
	constructor(s3, config) {
		this.s3 = s3;
		this.config = config;
	}

	retrieveClientCert() {
		const deferred = Promise.defer();

		this.s3.getObject(
			{ Bucket: this.config.bucket, Key: this.config.clientCertificatePath },
			 handleS3GetObject(deferred)
		);

		return deferred.promise;
	}

	retrieveClientKey() {
		const deferred = Promise.defer();

		this.s3.getObject(
			{ Bucket: this.config.bucket, Key: this.config.clientKeyPath },
			handleS3GetObject(deferred)
		);

		return deferred.promise;
	}

	_getCAFilePath(floCaVersion) {
		if(floCaVersion == 'v2') {
			return this.config.caV2FilePath
		} else {
			return this.config.caFilePath;
		}
	}

	retrieveCAFile(floCaVersion) {
		const deferred = Promise.defer();

		this.s3.getObject(
			{ Bucket: this.config.bucket, Key: this._getCAFilePath(floCaVersion) },
			handleS3GetObject(deferred)
		);

		return deferred.promise.then(file => file.Body);
	}

	retrieveAll(floCaVersion) {
		return Promise.all([
			this.retrieveClientCert(),
			this.retrieveClientKey(),
			this.retrieveCAFile(floCaVersion)
		]).then(([cert, key, ca]) => ({ cert, key, ca }));
	}

}

function handleS3GetObject(deferred) {
	return (err, data) => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve(data);
		}
	}
}

export default new DIFactory(MQTTCertService, [AWS.S3, TMQTTCertConfig]);