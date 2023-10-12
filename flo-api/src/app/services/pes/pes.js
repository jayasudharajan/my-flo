import moment from 'moment';
import axios from 'axios';
import config from '../../../config/config';
import ICDTable from '../../models/ICDTable';
import UserTable from '../../models/UserTable';
import UserDetailTable from '../../models/UserDetailTable';
import UserLocationRoleTable from '../../models/UserLocationRoleTable';
const icd = new ICDTable();
const user = new UserTable();
const userDetail = new UserDetailTable();
const userLocationRole = new UserLocationRoleTable();

const baseURL = config.pes;
const pes = axios.create({
  baseURL,
  timeout: 10000
});

function handleError(err) {
	if (err.response) {
		err.status = err.response.status;
	}

	return Promise.reject(err);
}

export const PROPOSAL_STATUS = {
	PROPOSED: 'PROPOSED',
	ACCEPTED: 'ACCEPTED',
	REJECTED: 'REJECTED'
};

export function addDevice(device_id, timezone = 'Etc/UTC') {
	const url = '/devices/';
	const data = {
	  device_id,
	  timezone: 'US/Pacific',
	  status: 'Initialized',
	  init_date: moment().toISOString()
	};

	return pes.post(url, data).catch(handleError);
}

export function deleteDevice(device_id) {
	const url = '/devices/' + device_id + '/';

	return pes.delete(url).catch(handleError);
}

export function listDevices() {
	const url = '/devices/';
	
	return pes.get(url).catch(handleError);
}

export function retrieveDevice(device_id) {
	const url = '/devices/' + device_id + '/';

	return pes.get(url).catch(handleError);
}

export function retrieveProposedParamsList() {
	const url = '/proposed_params/';

	return pes.get(url).catch(handleError);
}

export function acceptParams(device_id, overrideParams = {}) {
	const url = '/devices/' + device_id + '/accept_params/';

	return pes.post(url, overrideParams).catch(handleError);
}

export function rejectParams(device_id) {
	const url = '/devices/' + device_id + '/reject_params/';

	return pes.post(url, {}).catch(handleError);
}

export function forceCompute() {
	const url = '/compute_params/';

	return pes.post(url).catch(handleError);
}

export function retrieveParams(paramId) {
	const url = '/parameters/' + paramId + '/';

	return pes.get(url).catch(handleError);
}

export function retrieveProposedParamsUserList() {
	return retrieveProposedParamsList()
		.then(result => {
			const proposals = result.data
				.filter(({ proposed_params: { status } }) => status.toUpperCase() === PROPOSAL_STATUS.PROPOSED)
			const promises = proposals
				.map(proposal => leftJoin(
					proposal,
					({ device_id }) => icd.retrieveByDeviceId({ device_id }).then(takeFirst)
				))
				.map(promise => promise.then(icd => leftJoin(
					icd,
					({ location_id }) => userLocationRole.retrieveByLocationId({ location_id }).then(takeFirst)
				)))
				.map(promise => promise.then(userLocationRole => leftJoin(
					userLocationRole,
					({ user_id }) => Promise.all([user.retrieve({ id: user_id }), userDetail.retrieve({ user_id })])
				)))
				.map(promise => promise.then(userInfo => userInfo && {
					email: (userInfo[0].Item? userInfo[0].Item.email: undefined),
					firstname: (userInfo[1].Item? userInfo[1].Item.firstname: undefined),
					lastname: (userInfo[1].Item? userInfo[1].Item.lastname: undefined)
				}));

			return Promise.all(promises)
				.then(userInfos => userInfos.map((userInfo, i) => ({ user: { ...userInfo }, ...proposals[i] })));
		})
		.catch(handleError);
}

function leftJoin(left, join) {
	return !left ?
		new Promise(resolve => resolve()):
		join(left);
}

function takeFirst({ Items }) {
	return Items[0];
}
