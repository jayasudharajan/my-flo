import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import InfoService from '../info/InfoService';
import FirebaseAdminContainer from "./FirebaseAdminContainer";

class FirebaseTokenService {

  constructor(s3, infoService, firebaseAdminContainer) {
    this.s3 = s3;
    this.infoService = infoService;
    this.firebaseAdminContainer = firebaseAdminContainer;
  }

  issueToken(userId) {
    return this
      .infoService
      .users
      .retrieveByUserId(userId)
      .then(({ items: [ userInfo ] }) => {
        const additionalClaims = {
          device_ids: userInfo.is_system_user ? '*' : (userInfo.devices || []).map(device => device.device_id).join(',')
        };

        return this
          .firebaseAdminContainer
          .getAdmin()
          .then(admin => admin
            .auth()
            .createCustomToken(userId, additionalClaims)
            .then(token => ({
              token
            }))
          );
      });
  }
}

export default DIFactory(
  FirebaseTokenService,
  [AWS.S3, InfoService, FirebaseAdminContainer]
);

