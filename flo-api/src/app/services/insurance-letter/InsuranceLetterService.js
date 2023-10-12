import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';
import InsuranceLetterRequestLogTable from './InsuranceLetterRequestLogTable';
import LocationService from '../location-v1_5/LocationService';
import ICDService from '../icd-v1_5/ICDService';
import AccountService from '../account-v1_5/AccountService';
import UserAccountService from '../user-account/UserAccountService';
import moment from 'moment-timezone';
import _ from 'lodash';
import NotFoundException from '../utils/exceptions/NotFoundException';
import InsuranceLetterPDFCreator from './InsuranceLetterPDFCreator';

class InsuranceLetterService {

  constructor(s3, insuranceLetterPDFCreator, insuranceLetterRequestLogTable, locationService, accountService, userAccountService, icdService) {
    this.s3 = s3;
    this.insuranceLetterPDFCreator = insuranceLetterPDFCreator;
    this.locationService = locationService;
    this.accountService = accountService;
    this.userAccountService = userAccountService;
    this.insuranceLetterRequestLogTable = insuranceLetterRequestLogTable;
    this.icdService = icdService;
  }

  _getTemporaryUrl(registry) {
    const signedUrlExpireSeconds = 60 * 60;
    const s3 = this.s3;

    return new Promise(function(resolve, reject) {
      //We need to define the callback due to an issue with not setting is and the way that we define AWS Roles
      //otherwise could just use that what getObject returns
      s3.getSignedUrl('getObject', {
        Bucket: registry.s3_bucket,
        Key: registry.s3_key,
        Expires: signedUrlExpireSeconds
      }, (err, url) => {
        if(err) {
          reject(err);
        } else {
          resolve(url);
        }
      });
    });
  }

  _isValidRegistry(registry) {
    const currentTime = moment.utc();

    return moment.utc(registry.expiration_date).isAfter(currentTime) &&
      moment.utc(registry.renewal_date).isAfter(currentTime);
  }

  generate(locationId, userId) {
    return this
      .locationService
      .retrieveByLocationId(locationId)
      .then(locationResult => {
        const items = locationResult.Items;

        if(_.isEmpty(items)) {
          return Promise.reject(new NotFoundException('Location not found.'));
        }

        return Promise.all([
          items[0],
          this.accountService.retrieve(items[0].account_id)
        ]);
      })
      .then(([ location, accountResult ]) => {

        if(_.isEmpty(accountResult)) {
          return Promise.reject(new NotFoundException('Account not found for that location.'));
        }

        return Promise.all([
          location,
          this.userAccountService.retrieveUser(accountResult.Item.owner_user_id),
          this.insuranceLetterRequestLogTable.retrieveLatest({ location_id: locationId }),
          this.icdService.retrieveByLocationId(locationId),
        ]);
      })
      .then(([ location, user, insuranceLetterRegistryResult, devicesResult ]) => {
        const items = insuranceLetterRegistryResult.Items;
        const created_at = moment.utc().toISOString();
        const expiration_date = moment.utc().add(1, 'year').toISOString();
        const deviceItems = devicesResult.Items || [];
        const devices = deviceItems.map(({ id, device_type }) => ({ id, device_type }));

        if(_.isEmpty(items) || !this._isValidRegistry(items[0])) {
          return this
            .insuranceLetterRequestLogTable
            .create({
              location_id: locationId,
              created_at,
              expiration_date,
              renewal_date: moment.utc().add(1, 'year').toISOString(),
              generated_by_user_id: userId
            })
            .then(() => this.insuranceLetterPDFCreator.createInsuranceLetterPDF({
              location_id: locationId,
              created_at,
              expiration_date,
              user_id: user.id,
              first_name: user.firstname,
              last_name: user.lastname,
              street_address_1: location.address || '',
              street_address_2: '',
              city: location.city || '',
              state: location.state || '',
              zip: location.postalcode || '',
              time_zone: location.timezone || 'Etc/UTC',
              devices,
            }))
            .then(() => {});
        }

        return {};
      });
  }

  regenerate(locationId, userId) {
    return this
      .insuranceLetterRequestLogTable
      .retrieveLatest({ location_id: locationId })
      .then(insuranceLetterRegistryResult => {
        const items = insuranceLetterRegistryResult.Items;

        if(_.isEmpty(items)) {
          return Promise.resolve({});
        }

        return this
          .insuranceLetterRequestLogTable
          .patch(
            { location_id: locationId, created_at: items[0].created_at },
            { expiration_date: moment.utc().subtract(1, 'hour').toISOString() }
          );
      })
      .then(() => this.generate(locationId, userId));
  }

  getDownloadInfo(locationId) {
    return this
      .insuranceLetterRequestLogTable
      .retrieveLatest({ location_id: locationId })
      .then(registryResult => {
        const items = registryResult.Items;

        if(_.isEmpty(items) || !this._isValidRegistry(items[0])) {
          return { status: 'not-found' };
        }

        const registry = items[0];

        if(registry.s3_bucket && registry.s3_key) {
          return this
            ._getTemporaryUrl(registry)
            .then(url => ({
              status: 'ready',
              document_download_url: url,
              date_redeemed: registry.date_redeemed,
              expiration_date: registry.expiration_date,
              renewal_date: registry.renewal_date,
              redeemed_by_user_id: registry.redeemed_by_user_id
            }));
        }

        return { status: 'processing' };
      });
  }

  redeem(locationId, userId) {
    return this
      .insuranceLetterRequestLogTable
      .retrieveLatest({ location_id: locationId })
      .then(registryResult => {
        const items = registryResult.Items;

        if(_.isEmpty(items) || !this._isValidRegistry(items[0]) || !items[0].s3_bucket || !items[0].s3_key) {
          return Promise.reject(new NotFoundException('Insurance letter not found.'));
        }

        const registry = items[0];
        const keys = { location_id: registry.location_id, created_at: registry.created_at };
        const data = { date_redeemed: moment.utc().toISOString(), redeemed_by_user_id: userId };

        return this
          .insuranceLetterRequestLogTable
          .patch(keys, data)
          .then(() => {});
      });
  }
}

export default new DIFactory(
  InsuranceLetterService,
  [AWS.S3, InsuranceLetterPDFCreator, InsuranceLetterRequestLogTable, LocationService, AccountService, UserAccountService, ICDService]
);