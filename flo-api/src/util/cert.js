import fs from 'fs';
import config from '../config/config';
import AWS from 'aws-sdk';

var certs = null;

export function getCerts() {
	const deferred = Promise.defer();

	if (certs) {
		deferred.resolve(certs);
	} else {
		const clientCertDeferred = Promise.defer();
		const clientKeyDeferred = Promise.defer();
		const caFileDeferred = Promise.defer();
    const caV2FileDeferred = Promise.defer();

		const cfg = {
			region: config.aws.region,
			apiVersion: '2006-03-01'
		};
		const s3 = new AWS.S3(cfg);

		s3.getObject(createParams(config.clientCertificatePath), handleS3GetObject(clientCertDeferred));
		s3.getObject(createParams(config.clientKeyPath), handleS3GetObject(clientKeyDeferred));
		s3.getObject(createParams(config.mqttBroker.caFilePath), handleS3GetObject(caFileDeferred));
    s3.getObject(createParams(config.mqttBroker.caV2FilePath), handleS3GetObject(caV2FileDeferred));

		Promise.all([
			clientCertDeferred.promise,
			clientKeyDeferred.promise,
			caFileDeferred.promise,
      caV2FileDeferred.promise
		])
		.then(([cert, key, ca, caV2]) => {
			certs = { cert, key, ca, caV2 };
			deferred.resolve(certs);
		})
		.catch(err => deferred.reject(err));
	}

	return deferred.promise;
}

function createParams(key) {
	return {
		Bucket: config.certBucket,
		Key: key
	};
}

function handleRead(deferred) {
	return (err, data) => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve(data);
		}
	};
}

function handleS3GetObject(deferred) {
	return (err, data) => {
		if (err) {
			deferred.reject(err);
		} else {
			deferred.resolve(data.Body);
		}
	};
}