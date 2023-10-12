import express from 'express';
import DIFactory from  '../../../util/DIFactory';
import LocaleController from './LocaleController';

class LocaleRouter {
	constructor(localeController) {
		this.localeController = localeController;
		this.router = express.Router();


		this.router.route('/units/systems')
		.get(
			(...args) => this.localeController.listAllUnits(...args)
		);

		this.router.route('/units/systems/:system_id')
			.get(
				(...args) => this.localeController.retrieveUnitSystem(...args)
			);

		this.router.route('/')
			.get(
				(...args) => this.localeController.listAll(...args)
			);

		this.router.route('/:locale')
			.get(
				(...args) => this.localeController.retrieve(...args)
			);
	}
}

export default new DIFactory(LocaleRouter, [LocaleController]);