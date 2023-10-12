import _ from 'lodash';
import t from 'tcomb-validation';
import ValidationException from '../models/exceptions/ValidationException';

function reqValidate(validator) {
	const strict = validator && validator.strict;

	return (req, res, next) => {
		const errors = _.chain(req)
			.pick(['params', 'query', 'body'])
			.flatMap((sectionData, section) => {

				if (!_.isEmpty(sectionData) && !validator[section]) {
					return [ { message: `Unexpected ${ section } data`, path: null } ];
				} else if (validator[section]) {
					return t.validate(sectionData, validator[section], { strict }).errors;
				} else {
					return [];
				}
			})
			.value();

		if (errors.length) {
			next(new ValidationException(errors));
		} else {
			next();
		}
	};
}

export default reqValidate;