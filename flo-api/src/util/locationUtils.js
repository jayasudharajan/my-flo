import LocationTable from '../app/models/LocationTable';
import {errorTypes} from '../config/constants';

const Location = new LocationTable();

export function getTimezoneByLocationId(location_id) {
    Location.retrieveByLocationId({location_id})
        .then(({Items}) => {
            if (!Items || !Items.length) {
                throw errorTypes.LOCATION_NOT_FOUND;
            }

            return Items[0].timezone;
        });
}

export function getLocationEnumerationObject() {
    return {
        expansion_tank: {
            0: "No",
            1: "Yes",
            2: "Not Sure"
        },
        tankless: {
            0: "No",
            1: "Yes",
            2: "Not Sure"
        },
        water_filtering_system: {
            0: "No",
            1: "Yes",
            2: "Not Sure"
        },
        water_shutoff_known: {
            0: "No",
            1: "Yes",
            2: "Not Sure"
        },
        galvanized_plumbing: {
            0: "No",
            1: "Yes",
            2: "Not Sure"
        },
        location_size_category: {
            1: "< 700",
            2: "701-1000",
            3: "1001-2000",
            4: "2001-4000",
            5: " > 4000"
        },
        location_type: {
            sfh: "Single Family Home",
            apt: "Apartment",
            condo: "Condo"
        }
    }
}