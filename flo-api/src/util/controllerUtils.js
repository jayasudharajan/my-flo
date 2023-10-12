import _ from 'lodash';

export class CrudController {
	constructor(table) {
		this.table = table;
	}

	create(req) {
		return this.table.create({ ...(req.body || {}), ...(req.params || {}) });
	}

	update(req) {
		return this.table.update({ ...(req.body || {}), ...(req.params || {}) });
	}

	archive(req) {
		return this.table.archive(req.params || {});
	}

	remove(req) {
		return this.table.remove(req.params || {});
	}

	patch(req) {
		return this.table.patch(req.params || {}, req.body || {});
	}

	retrieve(req) {
		return this.table.retrieve(req.params || {})
			.then(result => result.Item || result);
	}
}

export class CrudServiceController {
	constructor(crudService) {
		this.service = crudService;
	}

	create(req) {
		return this.service.create({ ...(req.body || {}), ...(req.params || {}) });
	}

	update(req) {
		return this.service.update({ ...(req.body || {}), ...(req.params || {}) });
	}

	archive(req) {
		return this.service.archive(req.params || {});
	}

	remove(req) {
		return this.service.remove(req.params || {});
	}

	patch(req) {
		return this.service.patch(req.params || {}, req.body || {});
	}

	retrieve(req) {
		return this.service.retrieve(req.params || {})
			.then(result => result.Item || result);
	}	
}

function wrapController(wrapped, proto) {

	if (proto == Object.prototype) {
		return wrapped;
	} else {
		Object.getOwnPropertyNames(proto)
			.filter(protoPropName => _.isFunction(proto[protoPropName]) && protoPropName !== 'constructor' && !protoPropName.startsWith('_'))
			.forEach(method => wrapped.prototype[method] = wrapControllerFn(proto[method])); 

		return wrapController(wrapped, Object.getPrototypeOf(proto));
	} 
}

export function ControllerWrapper(controllerClass) {
	return wrapController(class extends controllerClass {}, controllerClass.prototype);
}

export function wrapControllerFn(controllerFn) {
	return function (req, res, next) {
		try {
			controllerFn.call(this, req, res, next)
				.then(result => res.json(result))
				.catch(next);
		} catch (err) {
			next(err);
		}
	};
}