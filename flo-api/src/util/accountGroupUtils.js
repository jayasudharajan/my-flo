import LocationTable from '../app/models/LocationTable';
import AccountTable from '../app/models/AccountTable';
import UserAccountRoleTable from '../app/models/UserAccountRoleTable';

import AccountGroupLogTable from '../app/models/AccountGroupLogTable';

import AccountGroupCache from './accountGroupCache';
import { getClient, withFallback } from './cache';

const location = new LocationTable();
const account = new AccountTable();
const userAccountRole = new UserAccountRoleTable();
const accountGroupLog = new AccountGroupLogTable();

function _lookupByAccountId(account_id, log) {
	let accountGroupCache = new AccountGroupCache(getClient());

	return _lookup(
		() => accountGroupCache.lookupByAccountId(account_id, true),
		() => retrieveByAccountId(account_id),
		({ group_id, created_at }) => accountGroupCache.cacheAccountId(group_id, account_id, created_at),
		log
	);
}

export function lookupByAccountId(account_id, log) {
	return _lookupByAccountId(account_id, log).then(({ group_id }) => group_id);
}


function retrieveByAccountId(account_id) {

	return retrieveFromLog('account.' + account_id, () => 
		account.retrieve({ id: account_id })
			.then(({ Item }) => {
				return Item;
			})
	);
}

export function lookupByLocationId(location_id, log) {
	let accountGroupCache = new AccountGroupCache(getClient());

	return lookup(
		() => accountGroupCache.lookupByLocationId(location_id, true),
		() => retrieveByLocationId(location_id),
		({ group_id, created_at }) => accountGroupCache.cacheLocationId(group_id, location_id, created_at),
		log
	);
}

function retrieveByLocationId(location_id) {
	return retrieveFromLog('location.' + location_id, () =>
		 location.retrieveByLocationId({ location_id })
			.then(({ Items }) => {
				if (Items && Items.length) {
					return _lookupByAccountId(Items[0].account_id);
				} 
			})
	);
}


export function lookupByUserId(user_id, log) {
	let accountGroupCache = new AccountGroupCache(getClient());

	return lookup(
		() => accountGroupCache.lookupByUserId(user_id, true),
		() => retrieveByUserId(user_id),
		({ group_id, created_at }) => accountGroupCache.cacheUserId(group_id, user_id, created_at),
		log
	);
}


function retrieveByUserId(user_id) {
	return retrieveFromLog('user.' + user_id, () => 
		userAccountRole.retrieveByUserId({ user_id })
			.then(({ Items }) => {
				if (Items && Items.length) {
					return _lookupByAccountId(Items[0].account_id);
				}
			})
	);
}

function lookup(cacheLookup, dbLookup, cacheInsert, log) {
	return _lookup(cacheLookup, dbLookup, cacheInsert, log)
	.then(({ group_id }) => group_id);
}

function _lookup(cacheLookup, dbLookup, cacheInsert, log) {
	return withFallback(
		() => cacheLookup(),
		() => dbLookup().then(result => (result || { fallbackFail: true })),
		result => {
			if (result && !result.fallbackFail && result.group_id) {
				 cacheInsert(result)
				 	.catch(err => {
				 		if (log) {
				 			log.error(err);
				 		}
				 	});
			}
		},
		log && ((isFromCache, result) => log.info({ cached_lookup: { isFromCache, result } }))
	)
	.then(result => {
		if (result && result.fallbackFail) {
			return '';
		} else {
			return result;
		}
	});
}

function retrieveFromLog(resourceKey, fallback) {
	return accountGroupLog.retrieveLatestByResource({ subresource: resourceKey })
		.then(({ Items }) => {

			if (Items && Items.length) {
				return { 
					group_id: Items[0].group_id, 
					created_at: new Date(Items[0].created_at).getTime() 
				};
			} else {
				return fallback();
			}
		});
}