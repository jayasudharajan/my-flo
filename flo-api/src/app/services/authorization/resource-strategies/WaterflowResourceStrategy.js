import ResourceStrategy from './ResourceStrategy';
import UserLocationRoleTable from '../UserLocationRoleTable';
import DIFactory from  '../../../../util/DIFactory';

class WaterflowResourceStrategy extends ResourceStrategy {
	constructor(userLocationRoleTable) {
		super('Waterflow', 'location_id', userLocationRoleTable);
	}
}

export default new DIFactory(WaterflowResourceStrategy, [UserLocationRoleTable]);