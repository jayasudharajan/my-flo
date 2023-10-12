import _ from 'lodash';
import DIFactory from  '../../../../util/DIFactory';
import AccountGroupResourceStrategy from './AccountGroupResourceStrategy';
import AccountResourceStrategy from './AccountResourceStrategy';
import LocationResourceStrategy from './LocationResourceStrategy';
import UserResourceStrategy from './UserResourceStrategy';
import SystemResourceStrategy from './SystemResourceStrategy';
import WaterflowResourceStrategy from './WaterflowResourceStrategy';
import IFTTTResourceStrategy from './IFTTTResourceStrategy';
import GoogleSmartHomeResourceStrategy from './GoogleSmartHomeResourceStrategy';

class ResourceStrategyFactory {
	constructor(...resourceStrategies) {
		this.resourceStrategies = resourceStrategies;
	}

	getResourceStrategy(resourceName) {
		return _.find(this.resourceStrategies, { resourceName });
	}

	getSubResourceRolesByUserId(userId) {
		return Promise.all(
			this.resourceStrategies
				.map(resourceStrategy => resourceStrategy.getSubResourceRolesByUserId(userId))
		)
		.then(subResourceRoles => _.flatten(subResourceRoles));
	}

	parseRole(role) {
		return this.resourceStrategies
			.map(resourceStrategy => resourceStrategy.parseRole(role))
			.filter(parsedRole => parsedRole)[0] || role;
	}
}

export default new DIFactory(ResourceStrategyFactory, [
	AccountGroupResourceStrategy,
	AccountResourceStrategy,
	LocationResourceStrategy,
	UserResourceStrategy,
	SystemResourceStrategy,
	WaterflowResourceStrategy,
	IFTTTResourceStrategy,
	GoogleSmartHomeResourceStrategy
]);