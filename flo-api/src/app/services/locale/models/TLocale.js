import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TLocale = t.struct({
	// locale should be a 2 letter abbreviation, e.g. US, UK, AU, DE, etc
	locale: t.String,
	// name is the actual name of the country, e.g. United States, Germany, Switzerland
	name: t.String,
	// region_type should be defined if there are any regions
	// e.g. 'state', 'province', etc
	region_type: t.maybe(t.String),
	// regions should be an empty list if there are no regions 
	regions: t.list(t.struct({ 
		abbrev: t.String,
		name: t.String,
		timezones: t.list(t.String)
	})),
	timezones: t.list(t.String)
});

TLocale.create = data => TLocale(data);

export default TLocale;