import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import LocationTable from './LocationTable';
import AuthorizationService from '../authorization/AuthorizationService';
import AccountService from '../account-v1_5/AccountService';
import TLocation from './models/TLocation';
import DIFactory from  '../../../util/DIFactory';
import uuid from 'uuid';
import NotFoundException from '../utils/exceptions/NotFoundException';

class LocationService {

	constructor(locationTable, authorizationService, accountService) {
	    this.locationTable = locationTable;
      this.authorizationService = authorizationService;
      this.accountService = accountService;
	}

	retrieve(accountId, locationId) {
		return this.locationTable.retrieve(accountId, locationId)
			.then(result => {
				if (_.isEmpty(result.Item)) {
					throw new NotFoundException('Location not found.');
				}

				return result;
			});
	}

	update(data) {
		return this.locationTable.update(data);
	}

	patch(accountId, locationId, data) {
		return this.locationTable.patch({ account_id: accountId, location_id: locationId }, data);
	}

	create(data) {
		const normalizedData = _.merge(
			{
				location_id: uuid.v4(),
				address: '',
				city: '',
				state: '',
				country: '',
				postalcode: '',
				timezone: '',
				expansion_tank: 2,
				tankless: 2,
				galvanized_plumbing: 2,
				water_filtering_system: 2,
				water_shutoff_known: 2,
        hot_water_recirculation: 2,
        whole_house_humidifier: 2,
				gallons_per_day_goal: 240,
				bathroom_amenities: [],
				kitchen_amenities: [],
				outdoor_amenities: []
			},
			data
		);

		return this.locationTable.create(normalizedData);
	}

  createInAccount( { account_id, ...data } ){
      const location_id = uuid.v4();
      return this.accountService.retrieve( account_id )
                .then(({ Item }) => {
                  if ( !Item ){
                    throw new NotFoundException( "Account not found" );  
                  }
                  if ( !Item.owner_user_id ) {
                    throw new NotFoundException( "No Associated owner on the account" );
                  }
                  return this.authorizationService.assignUserResourceRoles(Item.owner_user_id, 'Location', location_id, ['owner'], { account_id });
                })
                .then(() => this.create({account_id, location_id, ...data}))
                .then(() => ({ account_id, location_id }));
  }

	remove(accountId, locationId) {
		return this.locationTable.remove({ account_id: accountId, location_id: locationId })
	}

	archive(accountId, locationId) {
		return this.locationTable.archive({ account_id: accountId, location_id: locationId });
	}

	retrieveByAccountId(accountId) {
		return this.locationTable.retrieveByAccountId(accountId);
	}

	retrieveByLocationId(locationId) {
		return this.locationTable.retrieveByLocationId(locationId);
	}
}

export default new DIFactory(LocationService, [LocationTable, AuthorizationService, AccountService]);

