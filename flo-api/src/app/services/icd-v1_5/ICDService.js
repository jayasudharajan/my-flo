import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import ICDTable from './ICDTable';
import { validateMethod } from '../../models/ValidationMixin';
import DIFactory from  '../../../util/DIFactory';
import uuid from 'uuid';
import NotFoundException from '../utils/exceptions/NotFoundException';

class ICDService {
	constructor(icdTable) {
		this.icdTable = icdTable;
	}

	retrieve(icdId) {
		return this.icdTable.retrieve({ id: icdId });
	}

	update(data) {
		return this.icdTable.update(data);
	}

	patch(icdId, data) {
		return this.icdTable.patch({ id: icdId }, data);
	}

	create(data) {
		return this.icdTable.create({ id: uuid.v4(), ...data });
	}

	remove(icdId) {
		return this.icdTable.remove({ id: icdId });
	}

	archive(icdId) {
		return this.icdTable.archive({ id: icdId });
	}

	retrieveByLocationId(locationId) {
		return this.icdTable.retrieveByLocationId(locationId);
	}

	retrieveByDeviceId(deviceId) {
		return this.icdTable.retrieveByDeviceId(deviceId);
	}
}

export default DIFactory(ICDService, [ICDTable]);