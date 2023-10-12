import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import icdAlarmIncidentRegistryMapping from './mappings/icdalarmincidentregistries.js';
import icdAlarmIncidentRegistryLogMapping from './mappings/icdalarmincidentregistrylogs';
import { createFilterTypeFromMapping } from '../../utils/elasticsearchUtils';

const TIntegerString = t.refinement(t.String, s => Number.isInteger(new Number(s).valueOf()));
const icdAlarmIncidentRegistryFilterType = createFilterTypeFromMapping(icdAlarmIncidentRegistryMapping.icdalarmincidentregistry);
const icdAlarmIncidentRegistryLogFilterType = createFilterTypeFromMapping(icdAlarmIncidentRegistryLogMapping.icdalarmincidentregistrylog);

export default {
	retrieveByICDId: {
		query: t.struct({
			page: t.maybe(TIntegerString),
			size: t.maybe(TIntegerString),
			start: t.maybe(TIntegerString),
			end: t.maybe(TIntegerString)
		}),
		params: t.struct({
			icd_id: tcustom.UUIDv4
		}),
		body: icdAlarmIncidentRegistryFilterType
	},
	retrieveByIncidentId: {
		query: t.struct({
			start: t.maybe(TIntegerString),
			end: t.maybe(TIntegerString)
		}),
		params: t.struct({
			incident_id: tcustom.UUIDv4
		})
	},
	retrieveDeliveryAnalytics: {
		query: t.struct({
			start: t.maybe(TIntegerString),
			end: t.maybe(TIntegerString)
		}),
		body: icdAlarmIncidentRegistryLogFilterType
	}
};