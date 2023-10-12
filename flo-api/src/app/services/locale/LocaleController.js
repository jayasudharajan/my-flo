import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';
import LocaleService from './LocaleService';

class LocaleController {
	constructor(localeService) {
		this.localeService = localeService;
	}

	listAll() {
		return this.localeService.listAll();
	}

	retrieve({ params: { locale } }) {
		return this.localeService.retrieve(locale);
	}

  listAllUnits() {
    return this.localeService.listAllUnits();
  }

  retrieveUnitSystem({ params: { system_id } }) {
    return this.localeService.retrieveUnitSystem(system_id);
  }
}

export default new DIFactory(new ControllerWrapper(LocaleController), [LocaleService]);