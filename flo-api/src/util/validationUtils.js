import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../app/models/definitions/CustomTypes';

export function createCrudReqValidation({ hashKey, rangeKey }, typeValidator) {
	const typeProps = typeValidator.meta.props;	
	const paramValidator = t.struct({
		[hashKey]: typeProps[hashKey],
		...(rangeKey ? { [rangeKey]: typeProps[rangeKey] } : {})
	});

	return {
		retrieve: {
			params: paramValidator
		},
		archive: {
			params: paramValidator
		},
		remove: {
			params: paramValidator
		},
		create: {
			body: typeValidator
		},
		update: {
			params: paramValidator,
			body: t.struct({
				...typeProps,
				[hashKey]: tcustom.DefinedOrUndefined(typeProps[hashKey]),
				...(rangeKey ? { [rangeKey]: tcustom.DefinedOrUndefined(typeProps[rangeKey]) } : {})
			})
		},
		patch: {
			params: paramValidator,
			body: createPartialValidator(typeValidator)
		},
    delete: {
      params: paramValidator
		},
    archive: {
      params: paramValidator
    }
	};
}

export function createPartialValidator(type) {

	switch (type.meta.kind) {
		case 'struct':
			return t.struct(
					_.mapValues(type.meta.props, prop => tcustom.DefinedOrUndefined(createPartialValidator(prop)))
				);
		case 'list': 
			return t.list(createPartialValidator(type.meta.type));
		case 'dict':
			return t.dict(type.meta.domain, createPartialValidator(type.meta.codomain));
		default:
			return type;
	}
}

export function wrapEnum(enumType, isNumeric) {
	const reservedKeys = ['displayName', 'meta', 'is', 'kind', 'identity', 'name', 'map'];

	if (enumType.meta.kind !== 'enums') {
		throw new Error('Cannot wrap non enum type');
	}

	_.forEach(enumType.meta.map, (value, key) => {
		if (reservedKeys.indexOf(value) >= 0) {
			throw new Error(`Reserved keyword "${ value }"`);
		}
		// This looks backwards but this is how tcomb enums work
		// The key of the enum dictionary is the actual enumerated value
		// The value of the enum dictionary is just a nickname
		enumType[value] = isNumeric ? new Number(key).valueOf() : key;
	});

	enumType.getValues = () => 
		Object.keys(enumType.meta.map)
			.map(val => isNumeric ? new Number(val).valueOf() : val);

	enumType.getNames = () => _.map(enumType.meta.map, (value) => value);

	enumType.getNameByKey = (key) => enumType.meta.map[key];

	return enumType;
}