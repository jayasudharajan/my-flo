import _ from 'lodash';
import LocaleTable from './LocaleTable';
import moment from 'moment-timezone';
import DIFactory from  '../../../util/DIFactory';
import NotFoundException from '../utils/exceptions/NotFoundException';
import unitSystems from './models/unitSystems';

class LocaleService {
	constructor(localeTable) {
		this.localeTable = localeTable;
	}

	listAll() {
		return this.localeTable.listAll()
			.then(({ Items }) => ({
				locales: Items
			}));
	}

	retrieve(locale) {
		return this.localeTable.retrieve({ locale: locale.toLowerCase() })
			.then(({ Item: localeData }) => {
				if (!localeData) {
					return Promise.reject(new NotFoundException('Locale not found.'));
				}

				const timezones = localeData.timezones.map(parseTimezone).sort();
				const regions = _.chain(localeData.regions)
					.sortBy('abbrev')
					.map(region => ({
						...region,
						timezones: (region.timezones || []).map(parseTimezone).sort()
					}))
					.value();

				return {
					...localeData,
					regions,
					timezones
				};
			});
	}

	listAllUnits() {
		return Promise.resolve({
			systems: unitSystems
		});
	}

	retrieveUnitSystem(systemId) {
		return Promise.resolve(_.find(unitSystems, { id: systemId == 'default' ? 'imperial_us' : systemId }) || {});
	}
}

function parseTimezone(tz) {
	const name = tz.split('/').slice(1).map(area => area.split('_').join(' ')).join('/');

	return {
		tz,
		display: `UTC${ moment.tz(tz).format('Z z') } (${ name })`
	};	
}

export default new DIFactory(LocaleService, [LocaleTable]);