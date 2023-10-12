import { getAllControllerMethods } from './utils';

// If you have controller.myOpenEndpoint and do not want auth 
// for it, then you can:
// class FooAuthStrategy extends AuthStrategy {
//   constructor(authMiddleware, controller) {
//     super(authMiddleware, controller);
//   }

//   myOpenEndpoint(req, res, next) { 
//     next();
//   }
// }

export default class AuthStrategy {
	constructor(authMiddleware, controller, authOptions) {
		getAllControllerMethods(controller) 
			.forEach(method => {
				this[method] = authMiddleware.requiresAuth(authOptions);
			});
	}
}