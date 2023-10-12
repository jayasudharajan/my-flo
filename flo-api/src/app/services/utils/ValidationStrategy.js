import { getAllControllerMethods } from './utils';

export default class ValidationStrategy {
	constructor(validationMiddleware, requestTypes, controller) {
		getAllControllerMethods(controller)
			.forEach(method => {
				this[method] = validationMiddleware.reqValidate(requestTypes[method]);
			});
	}
}
