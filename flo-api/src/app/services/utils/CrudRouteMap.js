import _ from 'lodash';

export default class CrudRouteMap {
	// additionalRouteMap is for routes that should be mounted before the CRUD routes in order
	// to prevent conflicts
	constructor({ hashKey, rangeKey }, controller, additionalRouteMap) {
		const params = `:${ hashKey }` + (rangeKey ? `/:${ rangeKey }` : '');
		const crudRouteMap = {
			archive: {
				delete: `/archive/${ params }`
			},
			retrieve: {
				get: `/${ params }`
			},
			update: {
				post: `/${ params }`
			},
			patch: {
				put: `/${ params }`
			},
			remove: {
				delete: `/${ params }`
			},
			create: {
				post: '/'
			}
		};

		[additionalRouteMap, crudRouteMap]
			.forEach(routeMap => 
				_.chain(routeMap)
					.pickBy((value, key) => controller[key])
					.forEach((value, key) => this[key] = value)
					.value()
			);
	}
}