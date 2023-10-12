import ICDTable from '../app/models/ICDTable';
import { errorTypes } from '../config/constants';
import { client } from './elasticSearchProxy';
import { makeSearchResponse, getWildcardSearchRequestSet } from './elasticSearchHelper';

//import ICDLogTable from '../app/models/ICDLogTable';

let icd = new ICDTable();
//let icdLog = new ICDLogTable();

// Extremely ugly hack to get reconcililation service working
// Forgive me
export const icdTable = icd;

export function lookupByDeviceId(deviceId, log)  {
	return icd.retrieveByDeviceId({ device_id: deviceId })
	  .then(data => {
	  	const { Items } = data;
	  	
	    if (Items.length) {
	      return Items[0];
	    } else {
	      return new Promise((resolve, reject) => reject(errorTypes.ICD_NOT_FOUND));
	    }
	  });
}

export function lookupByICDId(icdId, log) {
	return icd.retrieve({ id: icdId })
		.then(data => {
			const { Item } = data;

			if (Item) {
				return Item;
			} else {
		      return new Promise((resolve, reject) => reject(errorTypes.ICD_NOT_FOUND));
			}

		});
}

export function lookupByLocationId(location_id, log) {
	return icd.retrieveByLocationId({ location_id })
		.then(data => {
			const { Items } = data;

			if (Items.length) {
				return Items[0];
			} else {
	      		return new Promise((resolve, reject) => reject(errorTypes.ICD_NOT_FOUND));
			}
		});
}

export function ensureICD({ device_id, icd_id, log }) {
    if (device_id && icd_id) {
        return new Promise(resolve => resolve({ device_id, icd_id }));
    } else if (device_id) {
        return lookupByDeviceId(device_id, log)
            .then(({ id }) => ({ device_id, icd_id: id }));
    } else if (icd_id) {
        return lookupByICDId(icd_id, log)
            .then(({ device_id }) => ({ device_id, icd_id }));
    } else {
        // TODO: Error
        return Promise((resolve, reject) => reject());
    }
}

export function scanAllUserDevice(size=0, page=1) {
	const parsedSize = parseInt(size) || 0;
	const from = (parseInt(page) - 1) * parsedSize;
	return client.search({
		index: 'users',
		size: parsedSize,
		from,
		body: {
			query: {
				nested: {
					path: 'devices',
					query: {
						match_all: {}
					}
				}
			},
			sort: [{ id: { order: 'asc' } }]
		}
	})
	.then(result => {
		return makeSearchResponse(result);
	})
}

export function fetchAllGroupUserDevice(group_id, size=0, page=1) {
	const parsedSize = parseInt(size) || 0;
	const from = (parseInt(page) - 1) * parsedSize;
	return client.search({
		index: 'users',
		size: parsedSize,
		from,
		body: {
			query: {
				bool: {
					must: [
						{ term: { 'account.group_id': group_id } },
						{ nested: {
							path: 'devices',
							query: {
								match_all: {}
							}
						}}
					]
				}
			},
			sort: [{ id: { order: 'asc' } }]
		}
	})
	.then(result => {
		return makeSearchResponse(result);
	})
}

export function searchUserDevice(match_string, size=0, page=1) {
	const parsedSize = parseInt(size) || 0;
	const from = (parseInt(page) - 1) * parsedSize;
	return client.search({
		index: 'users',
		size: parsedSize,
		from,
		body: {
			query: {
				bool: {
					must: [
						{ nested: {
								path: 'devices',
								query: {
									match_all: {}
								}
						}},
						{ bool: {
								should: getWildcardSearchRequestSet(
									match_string,
									['firstname', 'lastname', 'email', 'devices.device_id'])
						}}
					]
				}
			},
			sort: [{ id: { order: 'asc' } }]
		}
	})
	.then(result => {
		return makeSearchResponse(result);
	})
}

export function searchGroupUserDevice(group_id, match_string, size=0, page=1) {
	const parsedSize = parseInt(size) || 0;
	const from = (parseInt(page) - 1) * parsedSize;
	return client.search({
		index: 'users',
		size: parsedSize,
		from,
		body: {
			query: {
				bool: {
					must: [
						{ term: { 'account.group_id': group_id } },
						{ nested: {
							path: 'devices',
							query: {
								match_all: {}
							}
						}},
						{ bool: {
								should: getWildcardSearchRequestSet(
									match_string,
									['firstname', 'lastname', 'email', 'devices.device_id'])
						}}
					]
				}
			},
			sort: [{ id: { order: 'asc' } }]
		}
	})
	.then(result => {
		return makeSearchResponse(result);
	})
}
