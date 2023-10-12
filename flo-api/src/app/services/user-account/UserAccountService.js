import _ from 'lodash';
import uuid from 'uuid';
import { validateMethod } from '../../models/ValidationMixin';
import TUserData from './models/TUserData';
import TUserDataOptions from './models/TUserDataOptions';
import TUser from './models/TUser';
import TUserDetail from './models/TUserDetail';
import DIFactory from  '../../../util/DIFactory';
import AccountService from '../account-v1_5/AccountService';
import LocationService from '../location-v1_5/LocationService';
import UserTable from './UserTable';
import UserDetailTable from './UserDetailTable';
import AuthorizationService from '../authorization/AuthorizationService';
import TAccount from '../account-v1_5/models/TAccount';
import TLocation from '../location-v1_5/models/TLocation';

class UserAccountService {
	constructor(authorizationService, accountService, locationService, userTable, userDetailTable) {
		this.authorizationService = authorizationService;
		this.accountService = accountService;
		this.locationService = locationService;
		this.userTable = userTable;
		this.userDetailTable = userDetailTable;
	}
	

	createNewUserAndAccount(userData) {
		const userId = uuid.v4();
		const accountId = uuid.v4();
		const locationId = uuid.v4();
		const accountData = { 
			...extractData(userData, TAccount),
			id: accountId, 
			owner_user_id: userId 
		};
		const locationData = { 
			...extractData(userData, TLocation),
			account_id: accountId, 
			location_id: locationId 
		};

		return Promise.all([
			this.createUser(userData, userId),
			this.authorizationService.assignUserResourceRoles(userId, 'Account', accountId, ['owner']),
			this.authorizationService.assignUserResourceRoles(userId, 'Location', locationId, ['owner'], { account_id: accountId })
		])
		.then(() => this.accountService.create(accountData))
		.then(() => this.locationService.create(locationData))
		.then(() => ({ user_id: userId, account_id: accountId, location_id: locationId }))
		.catch(err => 
			// "Roll back" changes in case of error
			this.removeUserAndAccount(userId, accountId, locationId)
				.then(() => Promise.reject(err))
		)
	}

	removeUserAndAccount(userId, accountId, locationId) {
		return Promise.all([
				this.userTable.remove({ id: userId }),
				this.userDetailTable.remove({ user_id: userId }),
				this.accountService.remove(accountId),
				this.locationService.remove(accountId, locationId),
				this.authorizationService.removeUserResourceRoles(userId, 'Account', accountId),
				this.authorizationService.removeUserResourceRoles(userId, 'Location', locationId)
			]);
	}

	createUser(data, userId = uuid.v4()) {
		const { user, userDetail } = separateUserData(data);
		const options = deriveOptions(data)
		return Promise.all([
			this.userTable.create({
				is_active: false,
				...user,
				id: userId
			}, options),
			this.userDetailTable.create({
				locale: 'en-us',
				...userDetail,
				user_id: userId
			})
		]);
	}

	patchUser(userId, userData) {
		const { user, userDetail } = separateUserData(userData);

		return Promise.all([
			_.isEmpty(user) ? Promise.resolve() : this.userTable.patch({ id: userId }, user),
			_.isEmpty(userDetail) ? Promise.resolve() : this.userDetailTable.patch({ user_id: userId }, userDetail)
		]);
	}

	retrieveUser(userId) {
		return Promise.all([
			this.userTable.retrieve({ id: userId }),
			this.userDetailTable.retrieve({ user_id: userId })
		])
		.then(([{ Item: user }, { Item: userDetail }]) => ({
			...user,
			...(_.omit(userDetail, ['user_id']))
		}));
	}

	retrieveUserByEmail(email) {
		return this.userTable.retrieveByEmail(email)
			.then(({ Items: [user] }) => !user ?
				null :
				this.userDetailTable.retrieve({ user_id: user.id })
					.then(({ Item: userDetail = {} }) => ({
						...user,
						...(_.omit(userDetail, ['user_id']))
					}))
			);
	}

	retrieveAccountIdByUserId(userId) {
		return this.authorizationService.retrieveUserResources(userId, 'Account')
			.then(resourceIds => _.isEmpty(resourceIds) ? null : resourceIds[0]);
	}
}

function separateUserData(data) {
	const user = _.pick(data, _.keys(TUser.meta.props));
	const userDetail = _.pick(data, _.keys(TUserDetail.meta.props));

	return { user, userDetail };
}

function deriveOptions(data) {
	return _.pick(data, _.keys(TUserDataOptions.meta.props))
}

function extractData(data, typeDef) {
	const props = _.intersection(
		_.keys(TUserData.meta.props),
		_.keys(typeDef.meta.props)
	);

	return _.pick(data, props);
}

validateMethod(
	UserAccountService.prototype,
	'createNewUserAndAccount',
	[TUserData]
);

export default new DIFactory(UserAccountService, [AuthorizationService, AccountService, LocationService, UserTable, UserDetailTable]);
