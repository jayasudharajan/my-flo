import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';

export function createTypeFromMapping(mapping) {
	return t.struct(
		_.mapValues(mapping.properties, property => {
			switch (property.type) {
				case 'keyword':
				case 'text':
				case 'string':
					return t.String;
				case 'boolean':
					return t.Boolean;
				case 'float':
					return t.Number;
				case 'integer':
					return tcustom.Integer32;
				case 'date':
					return tcustom.ISO8601Date;
				case 'nested':
					return t.list(createTypeFromMapping(property));
				case 'object':
					return createTypeFromMapping(property);
				default:
					throw new Error('Unknown mapping type.');
			}
		})
	);
}

function createRangeFilterType(type) {
	return t.refinement(
		t.interface({
			lt: t.maybe(type),
			gt: t.maybe(type),
			lte: t.maybe(type),
			gte: t.maybe(type)
		}),
		obj => ['lt', 'gt', 'lte', 'gte'].some(comparison => !_.isNil(obj[comparison]))
	);
}

function createNegatedFilterType(type) {
	return t.interface({
		not: type
	});
}


function _createFilterTypeFromMapping(mapping) {
	const dataType = createTypeFromMapping(mapping);
	const filterType = t.struct(
		_.reduce(mapping.properties, (acc, propertyValue, propertyName) => {
			switch (propertyValue.type) {
				case 'keyword':
				case 'text':
				case 'string':
					return {
						...acc,
						[propertyName]: t.union([
							t.list(t.String),
							createRangeFilterType(t.String),
							t.interface({ wildcard: t.String }),
							t.interface({ prefix: t.String })
						])
					};
				case 'boolean':
					return {
						...acc,
						[propertyName]: t.list(t.Boolean)
					};
				case 'float':
					return {
						...acc,
						[propertyName]: t.union([
							t.list(t.Number),
							createRangeFilterType(t.Number)
						])
					};
				case 'integer':
					return {
						...acc,
						[propertyName]: t.union([
							t.list(tcustom.Integer32),
							createRangeFilterType(tcustom.Integer32)
						])
					};
				case 'date':
					return {
						...acc,
						[propertyName]: t.union([
							t.list(tcustom.ISO8601Date),
							createRangeFilterType(t.String) // TODO: Maybe define partial date type?
						])
					};
				case 'nested':
					return {
						...acc,
						..._createFilterTypeFromMapping({
							properties: _.mapKeys(
								propertyValue.properties, 
								(type, nestedPropertyName) => `[${propertyName}.${nestedPropertyName}]`
							)
						}).meta.props
					};
				case 'object':
					return {
						...acc,
						..._createFilterTypeFromMapping({
							properties: _.mapKeys(
								propertyValue.properties, 
								(type, nestedPropertyName) => `${propertyName}.${nestedPropertyName}`
							)
						}).meta.props
					};
				default:
					throw new Error('Unknown mapping type.');
			}
		}, {})
	);
	const types = t.struct(
		_.mapValues(
				filterType.meta.props, 
				(filterPropType, propName) => 
					t.maybe(
						dataType.meta.props[propName] ?
							t.union([filterPropType, dataType.meta.props[propName]]) :
							filterPropType
					)
		)
	);

	return t.struct(
		_.mapValues(
			types.meta.props,
			type => t.union([type, createNegatedFilterType(type)])
		)
	);
}

export function createFilterTypeFromMapping(mapping) {
	return t.struct({
		query: t.maybe(t.String),
		filter: t.maybe(_createFilterTypeFromMapping(mapping))
	});
}