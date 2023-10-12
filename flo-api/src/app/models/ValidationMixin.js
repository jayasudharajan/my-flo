import t from 'tcomb-validation';
import _ from 'lodash';
import ValidationException from './exceptions/ValidationException';
import { createPartialValidator } from '../../util/validationUtils';

export function validateMethod(proto, methodName, domainValidators, bypassPromise) {
	const method = proto[methodName];

	proto[methodName] = function () {
		const failingValidation = _.chain(domainValidators)
			.map((validator, i) => t.validate(arguments[i], validator))
			.find(validation => !validation.isValid())
			.value();

		if (!failingValidation) {
			return method.apply(this, arguments);
		} else if (bypassPromise) {
			throw new ValidationException(failingValidation.errors);
		} else {
			return new Promise((resolve, reject) => reject(new ValidationException(failingValidation.errors)));
		}
	};
}

export const ValidationMixin = (typeValidator, baseClass) => {
	const partialValidator = createPartialValidator(typeValidator);
	const validatedClass = class extends baseClass {
		getType() { return typeValidator; }
	};

	validateMethod(
		validatedClass.prototype,
		'create',
		[typeValidator]
	);

	validateMethod(
		validatedClass.prototype,
		'update',
		[typeValidator]
	);

	validateMethod(
		validatedClass.prototype,
		'patch',
		[partialValidator, partialValidator]
	);

	return validatedClass;
}

export default ValidationMixin;