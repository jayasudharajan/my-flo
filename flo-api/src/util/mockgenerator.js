import _ from 'lodash';

var randomMac = require('random-mac');

import { firstnames_male, 
		 firstnames_female, 
		 lastnames,
		 streetnames,
		 cities_withzip } from './mockdata';

/**
 * Return a random int.
 * @param  {int} low  low number, inclusive.
 * @param  {int} high high number, exclusive.
 * @return {int}      number.
 */
function randomInt (low, high) {
	return Math.floor(Math.random() * (high - low) + low);
}

/**
 * Return a mocked user.
 * @return {Object} user.
 */
export function createUser() {
    
    let user = {
    	firstname: '',
    	lastname: '',
    	username: '',
    	email: ''
    };

    // Get gender based random firstname.
    let idx = randomInt(0, 2);
    if(idx) {
    	idx = randomInt(0, firstnames_male.length - 1);
    	user.firstname = firstnames_male[idx];
    } else {
    	idx = randomInt(0, firstnames_female.length - 1);
    	user.firstname = firstnames_female[idx];
    }
    
    // Get random lastname.
    idx = randomInt(0, lastnames.length - 1);
    user.lastname = lastnames[idx];

    // Construct username.
    idx = randomInt(1000, 9999);
    user.username = _.toLower(user.firstname) + _.toLower(user.lastname) + _.toString(idx);

    // Construct email.
    user.email = "flobot." + user.username + "@mailinator.com";

	return user;

}

/**
 * Return a mocked address.
 * @return {Object} address.
 */
export function createAddress() {
    
    let address = {
        name: 'My House',
    	address: '',
    	address2: '',
    	city: '',
    	state: '',
    	zipcode: ''
    };

    // Make street number - 1/3 = 1-100, 1/3 = 101-1000, 1/3 = 1001-9999.
    let street_num = 0;
    let street_num_type = randomInt(0, 3);
    switch (street_num_type) {
    	case 0:
			street_num = randomInt(1, 101);
			break;
    	case 1:
			street_num = randomInt(101, 1001);
			break;
    	default:
			street_num = randomInt(1001, 10000);
	}

    // Get address.
    let idx = randomInt(0, streetnames.length - 1);
    address.address = _.toString(street_num) + " " + streetnames[idx];

    // Get city, state, zip.
    idx = randomInt(0, cities_withzip.length - 1);
    let city_str = cities_withzip[idx].split(",");
    address.city = city_str[0];
    address.state = city_str[1];
    address.zipcode = city_str[2];

	return address;

}

/**
 * Create mock zone data.
 * @return {Object} zone data.
 */
export function createZone() {

    let home_size = randomInt(800, 4000);
    let number_of_constant_occupants = randomInt(1, 7);
    let number_of_bathrooms = randomInt(1, 5);
    return {
        "name": "Zone 1",
        "home_size": home_size,
        "number_of_constant_occupants": number_of_constant_occupants,
        "valve_number": randomMac(),
        "number_of_bathrooms": number_of_bathrooms,
        "shutoff_valve_on_vacation": true,
        "valve_name": "I2CD",
        "valve_status": 0
    }

}
