import ResourceStrategy from './ResourceStrategy';
import UserLocationRoleTable from '../UserLocationRoleTable';
import DIFactory from  '../../../../util/DIFactory';

class LocationResourceStrategy extends ResourceStrategy {
	constructor(userLocationRoleTable) {
		super('Location', 'location_id', userLocationRoleTable);
	}
}

export default new DIFactory(LocationResourceStrategy, [UserLocationRoleTable]);