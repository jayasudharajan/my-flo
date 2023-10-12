import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createPartialValidator } from '../../../../util/validationUtils';
import icdMapping from './mappings/icds';
import userMapping from './mappings/users';
import { createFilterTypeFromMapping } from '../../utils/elasticsearchUtils';
import TSubscriptionStatus from '../../subscription/models/TSubscriptionStatus';


const TPage = t.refinement(
	t.String, 
	s => Number.isInteger(new Number(s).valueOf()) && parseInt(s) > 0
);

TPage.getValidationErrorMessage = (actual, expected, path, context) => (path || expected) + ' must be an integer >= 1';


const TSize = t.refinement(
	t.String, 
	s => Number.isInteger(new Number(s).valueOf()) && parseInt(s) >= 0
);

TSize.getValidationErrorMessage = (actual, expected, path, context) => (path || expected) + ' must be an integer >= 0';

const TMSTimestamp =  t.refinement(
	t.String, 
	s => Number.isInteger(new Number(s).valueOf()) && parseInt(s) >= 0
);

TMSTimestamp.getValidationErrorMessage = (actual, expected, path, context) => (path || expected) + ' must be an integer >= 0';

const TLeakStatus = t.enums.of([
	'has_leak',
	'no_leak',
	'interrupted',
	'delayed',
	'unknown'
]);

const paginationValidator = t.struct({
	size: t.maybe(TSize),
	page: t.maybe(TPage)
});

const groupValidator = t.struct({
	group_id: tcustom.UUIDv4
});

const userIdValidator = t.struct({
	user_id: tcustom.UUIDv4
});

const icdValidator = t.struct({
	icd_id: tcustom.UUIDv4
});

const TUserFilter = createFilterTypeFromMapping(userMapping.user);
const TICDFilter = createFilterTypeFromMapping(icdMapping.icd);

export default {
	retrieveAllUsers: {
		query: paginationValidator,
		body: TUserFilter
	},
	retrieveAllGroupUsers: {
		query: paginationValidator,
		params: groupValidator,
		body: TUserFilter
	},
	retrieveUserByUserId: {
		params: userIdValidator
	},
	retrieveGroupUserByUserId: {
		params: groupValidator.extend(userIdValidator)
	},
	retrieveAllICDs: {
		query: paginationValidator,
		body: TICDFilter
	},
	retrieveAllGroupICDs: {
		query: paginationValidator,
		params: groupValidator,
		body: TICDFilter
	},
	retrieveICDByICDId: {
		params: icdValidator
	},
	retrieveGroupICDByICDId: {
		params: groupValidator.extend(icdValidator)
	},
	aggregateICDsByOnboardingEvent: {
		query: t.struct({
			start: t.maybe(TMSTimestamp),
			end: t.maybe(TMSTimestamp)
		}),
		body: TICDFilter
	},
	retrieveDevicesLeakStatus: {
		query: paginationValidator,
		body: t.struct({
			begin: tcustom.ISO8601Date,
			end: tcustom.ISO8601Date,
			leak_status: t.maybe(t.list(TLeakStatus)),
			subscription_status: t.maybe(t.list(t.union([TSubscriptionStatus, t.enums.of(['no_subscription'])])))
		})
	},
	retrieveLeakStatusCounts: {
		body: t.struct({
			begin: tcustom.ISO8601Date,
			end: tcustom.ISO8601Date,
		})
	},
	retrieveAllICDsWithScroll: {
		query: t.struct({
			size: t.maybe(TSize),
			scroll_ttl: t.maybe(t.String)
		}),
		body: TICDFilter
	},
	scrollAllICDs: {
		query: t.struct({
			scroll_ttl: t.maybe(t.String)
		}),
		params: t.struct({
			scroll_id: t.String
		})
	}
}