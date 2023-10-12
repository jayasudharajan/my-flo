import t from 'tcomb-validation';
import TUltimaVersion from './TUltimaVersion'
import { createCrudReqValidation } from '../../../../util/validationUtils';

export default {
	...createCrudReqValidation({ hashKey: 'model', rangeKey: 'version' }, TUltimaVersion),
	queryPartition: {
		params: t.struct({
			model: t.String
		})
	}
};






