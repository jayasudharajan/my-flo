import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAccount from './TAccount';
import { createPartialValidator } from  '../../../../util/validationUtils';

const paramsValidator = t.struct({
	id: tcustom.UUIDv4
});

export const archive = {
	params: paramsValidator
};

export const retrieve = {
	params: paramsValidator
};

export const remove = {
	params: paramsValidator
};

export const update = {
	params: paramsValidator,
	body: TAccount
};

export const patch = {
	params: paramsValidator,
	body: createPartialValidator(TAccount)
};

export const retrieveByGroupId = {
	params: t.struct({
		group_id: tcustom.UUIDv4
	})
};

export const retrieveByOwnerUserId = {
	params: t.struct({
		owner_user_id: tcustom.UUIDv4
	})
};