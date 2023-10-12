import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { directiveDataMap } from './directiveData';

const TDirectiveRequestParams = t.struct({
	icd_id: tcustom.UUIDv4,
	user_id: t.maybe(tcustom.UUIDv4)
});

const validations = _.mapValues(
	directiveDataMap,
	dataValidator => ({
		params: TDirectiveRequestParams,
		body: dataValidator	
	})
);

validations.retrieveDirectiveLogByDirectiveId = {
  params: t.struct({
		directive_id: tcustom.UUIDv4
	})
};

export default validations;