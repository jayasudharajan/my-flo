import express from 'express';
import _ from 'lodash';
import { getAllControllerMethods } from './utils';

class _Router {
	constructor(controller, routeMap, middlewareFactory) {
		const controllerMethods = getAllControllerMethods(controller);

		this.router = express.Router();
		this.routeMap = routeMap;
		this.controller = controller;

		_.forEach(this.routeMap, (routes, controllerMethod) => {
			(Array.isArray(routes) ? routes : [routes])
				.forEach(route => {
					const httpMethod = Object.keys(route)[0];
					const urlTemplate = route[httpMethod];
					const middleware = middlewareFactory(controllerMethod);

					this.router.route(urlTemplate)[httpMethod](
						...middleware,
						(...args) => this.controller[controllerMethod](...args),
						this.handleError(controllerMethod)
					)
				});
		});
	}

	handleError(controllerMethod) {
		return (err, req, res, next) => {
			next(err);
		};
	}
}

export default class Router extends _Router {

	constructor(authStrategy, validationStrategy, aclStrategy, controller, routeMap, middleware = []) {
		
		super(controller, routeMap,	controllerMethod => ([
			(...args) => this.authStrategy[controllerMethod](...args),
			(...args) => this.validationStrategy[controllerMethod](...args),
			(...args) => this.aclStrategy[controllerMethod](...args),
			...middleware
		]));

		this.authStrategy = authStrategy;
		this.validationStrategy = validationStrategy;
		this.aclStrategy = aclStrategy;

	}
}

