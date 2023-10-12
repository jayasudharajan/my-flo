import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TLocation from './TLocation';
import { createPartialValidator } from '../../../../util/validationUtils';

const paramsValidator = t.struct({
	account_id: tcustom.UUIDv4,
	location_id: tcustom.UUIDv4
});

const TPartialLocation = createPartialValidator(TLocation);

export const archive = {
	params: paramsValidator
};

export const retrieve = {
	params: paramsValidator
};

export const remove = {
	params: paramsValidator
};

export const create = {
	body: TPartialLocation
};

export const update = {
	params: paramsValidator,
	body: TLocation
};

export const patch = {
	params: paramsValidator,
	body: TPartialLocation
};

export const createByAccountId = {
	params: t.struct({
		account_id: tcustom.UUIDv4
	}),
	body: TPartialLocation
};

export const retrieveByLocationId = {
	params: t.struct({
		location_id: tcustom.UUIDv4
	})
};

export const retrieveByAccountId = {
	params: t.struct({
		account_id: tcustom.UUIDv4
	})
};
