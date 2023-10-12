import DIFactory from  '../../../util/DIFactory';
import * as firebaseAdmin from 'firebase-admin';
import AWS from 'aws-sdk';
import config from '../../../config/config';

var wasInitialized = false;

class FirebaseAdminContainer {

  constructor(s3Cient) {
    this.s3Cient = s3Cient;
  }

  _handleS3GetObject(deferred) {
    return (err, data) => {
      if (err) {
        deferred.reject(err);
      } else {
        deferred.resolve(data);
      }
    }
  }

  _getDevicePresenceFirebaseAdminCredentials() {
    const deferred = Promise.defer();

    this.s3Cient.getObject(
      { Bucket: config.appsConfigBucket, Key: config.devicePresenceFirebaseAdminCredentialsPath },
      this._handleS3GetObject(deferred)
    );

    return deferred.promise.then(data => JSON.parse(data.Body.toString()));
  }

  getAdmin() {
    if(wasInitialized) {
      return Promise.resolve(firebaseAdmin);
    }

    wasInitialized = true;

    return this._getDevicePresenceFirebaseAdminCredentials()
      .then(credentials => {
        firebaseAdmin.initializeApp({
          credential: firebaseAdmin.credential.cert(credentials),
          databaseURL: config.devicePresenceDatabaseUrl
        });

        return firebaseAdmin;
      });
  }
}

export default DIFactory(
  FirebaseAdminContainer,
  [AWS.S3]
);

