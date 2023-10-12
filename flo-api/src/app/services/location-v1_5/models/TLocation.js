import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TNoYesUnsure = t.enums.of([0,1,2]);
const TLocationSizeCategory = t.enums.of([0,1,2,3,4]);
const TLocationType = t.enums.of(['sfh', 'apt', 'condo', 'irrigation']);
const TBathroomAmenities = t.enums.of(['Hot Tub', 'Spa', 'Bathtub']);
const TKitchenAmeninites = t.enums.of(['Dishwasher', 'Washer / Dryer', 'Fridge with Ice Maker']);
const TOutdoorAmenities = t.enums.of(['Hot Tub', 'Sprinklers', 'Spa', 'Swimming Pool', 'Fountains']);

const TLocation = t.struct({
	account_id: tcustom.UUIDv4,
	location_id: tcustom.UUIDv4, 
	location_name: t.maybe(t.String),
	// Geography
	address: t.String,
	address2: t.maybe(t.String),
	city: t.String,
	state: t.String,
	country: t.String,
	postalcode: t.String,
	timezone: t.String,
	// Home profile
	expansion_tank: TNoYesUnsure,
	tankless: TNoYesUnsure,
	galvanized_plumbing: TNoYesUnsure,
	water_filtering_system: TNoYesUnsure,
	water_shutoff_known: TNoYesUnsure,
	hot_water_recirculation: TNoYesUnsure,
	whole_house_humidifier: TNoYesUnsure,
	location_size_category: t.maybe(TLocationSizeCategory),
	location_type: t.maybe(TLocationType),
	occupants: t.maybe(t.Integer),
	stories: t.maybe(t.Integer),
	gallons_per_day_goal: t.Number,
	// Amenities
	bathroom_amenities: t.list(TBathroomAmenities),
	kitchen_amenities: t.list(TKitchenAmeninites),
	outdoor_amenities: t.list(TOutdoorAmenities),
	is_profile_complete: t.maybe(t.Boolean),
	is_using_away_schedule: t.maybe(t.Boolean)
});

TLocation.create = data => TLocation(data);

export default TLocation;