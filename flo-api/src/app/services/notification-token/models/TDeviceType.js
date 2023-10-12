import t from 'tcomb-validation';

const TDeviceType = t.enums.of([
	'ios',
	'android'
]);

export default TDeviceType;