import _ from 'lodash';
import NotFoundException from './exceptions/NotFoundException';
import t from 'tcomb-validation';
import { validateMethod } from '../../models/ValidationMixin';

const TOptions = t.struct({
	size: t.maybe(t.refinement(t.union([t.Number, t.String]), n => Number.isInteger(new Number(n).valueOf()) && parseInt(n) >= 0)),
	page: t.maybe(t.refinement(t.union([t.Number, t.String]), n =>  Number.isInteger(new Number(n).valueOf()) && parseInt(n) > 0)),
	filter: t.maybe(t.Any), // Different for each index
	sort: t.maybe(t.Any), // Different for each index
	query: t.maybe(t.String)
});

class ElasticsearchIndex {
	constructor(indexName, elasticsearchClient) {
		this.indexName = indexName;
		this.elasticsearchClient = elasticsearchClient;
	}

	retrieveAll(options) {
		return this._retrieveAll(this.indexName, options);
	}

	retrieveAllWithScroll({ scrollTTL, ...options }) {
		return this._retrieveAll(this.indexName, options, scrollTTL);
	}

	scroll(scrollId, scrollTTL = '10s') {
		return this.elasticsearchClient.scroll({
			scroll_id: scrollId,
			scroll: scrollTTL
		})
		.then(result => this._normalizeSearchResult(result));
	}

	calculatePaging({ size, page }) {
		return {
			size,
			from: Math.max(page - 1, 0) * size
		};
	}

	_processOptions(options = {}) {
		const { size = 10, page = 1, filter = {}, sort, query } = options;
		const from = (page - 1) * size;

		return { ...this.calculatePaging({ size, page }), filter, sort, query: query && query.trim() };
	}

	_retrieveAll(index, options, scrollTTL) {
		const { size, from, filter, query: queryString, sort: sortOptions } = this._processOptions(options);
		const query = this._createQuery({ filter, query: queryString });
		const sort = sortOptions && !_.isEmpty(sortOptions) ? { sort: createSorts(sortOptions) } : {};

		return this.elasticsearchClient.search({
			index,
			from,
			size,
			...(scrollTTL ? { scroll: scrollTTL } : {}), 
			body: {	
				...sort,
				query
			}
		})
		.then(result => this._normalizeSearchResult(result));
	}

	retrieve(doctype, id) {
		return this._retrieve(this.indexName, doctype, id);
	}

	_retrieve(index, doctype, id) {
		return this.elasticsearchClient.get({
			index,
			type: doctype,
			id: id
		})
		.then(result => this._normalizeGetResult(result))
		.catch(error => this._normalizeGetError(error, `${ doctype } not found.`));
	}

	_normalizeSearchResult(result) {
	    return {
	        total: result.hits.total,
	        items: result.hits.hits.map(item => item._source),
	        ...(result._scroll_id ? { scrollId: result._scroll_id } : {})
	    };
	}

	_normalizeGetResult(result) {
		return {
			total: result.found ? 1 : 0,
			items: [result._source]
		};
	}

	_normalizeAggregationResult(result) {
		return {
			total: result.hits.total,
			items: result.hits.map(item => item._source),
			aggregations: result.aggregations
		};
	}

	_normalizeGetError(err, notFoundMessage) {
		if (err.statusCode == 404) {
			throw new NotFoundException(notFoundMessage);
		} 

		throw err;
	}

	_createQuery({ query, filter }) {

		if (_.isEmpty(filter) && _.isEmpty(query)) {
			return { match_all: {} };
		}

		const matchQuery = !query ? {} : this._createMatchQuery(query);
		const filterQuery = createFilters(filter);

		return {
			bool: {
				...matchQuery,
				...filterQuery
			},
		};
	}

	_createMatchQuery(query) {
		return {};
	}
}

validateMethod(
	ElasticsearchIndex.prototype,
	'_processOptions',
	[TOptions],
	true
);

export default ElasticsearchIndex;

export function createFilterQuery(filters) {
	return {
		bool: createFilters(filters)
	};
}

function createFilters(filters = {}) {
	const termFilters = createTermFilters(filters);
	const rangeFilters = createRangeFilters(filters);
	const nestedFilters = createNestedFilters(filters);
	const wildcardFilters = createWildcardFilters(filters);
	const prefixFilters = createPrefixFilters(filters);
	const notFilters = createNotFilters(filters);

	return {
		filter: [
			...termFilters,
			...nestedFilters,
			...rangeFilters,
			...wildcardFilters,
			...prefixFilters
		],
		...(
			notFilters.length ?
				{ must_not: notFilters } :
				{}
		)
	};
}

function isNotFilter(value) {
	return _.isObject(value) && value.not;
}

function createNotFilters(filters) {
	const unwrappedFilters = _.chain(filters)
		.omitBy((value, key) => isNestedFilter(key))
		.pickBy(value => isNotFilter(value))
		.mapValues(({ not: filter }) => filter)
		.value();

	if (_.isEmpty(unwrappedFilters)) {
		return [];
	} else {
		return createFilters(unwrappedFilters).filter;
	}
}

function isRecursiveFilter(key, value) {
	return isNotFilter(value) || isNestedFilter(key);
}

function createTermFilters(filters) {
	return _.chain(filters)
		.omitBy((value, key) => isRecursiveFilter(key, value))
		.pickBy(value => 
			_.isString(value) || 
			_.isBoolean(value) || 
			_.isNumber(value) || 
			_.isArray(value)
		)
		.map((value, key) => ({
			[_.isArray(value) ? 'terms' : 'term']: {
				[key]: value
			}
		}))
		.value();
}


function createRangeFilters(filters) {
	return _.chain(filters)
		.omitBy((value, key) => isRecursiveFilter(key, value))
		.pickBy(value => isRangeFilter(value))
		.map((value, key) => ({
			range: {
				[key]: _.pick(value, ['lt', 'gt', 'lte', 'gte'])
			}
		}))
		.value();
}

function createNestedFilters(filters) {
	return _.chain(filters)
		.pickBy((value, key) => isNestedFilter(key))
		.mapKeys((value, key) => key.slice(1, key.length - 1))
		.map((value, key) => ({ field: key, term: value }))
		.groupBy(({ field }) => field.split('.')[0])
		.map((value, key) => {
			const path = key;
			const pathFilters = value.reduce((acc, { field, term }) => ({
				...acc,
				[field]: term
			}), {});

			return {
				nested: {
					path,
					query: createFilterQuery(pathFilters)
				}
			};
		})
		.value();
}

function createPrefixFilters(filters) {
	return _.chain(filters)
		.omitBy((value, key) => isRecursiveFilter(key, value))
		.pickBy(value => isPrefixFilter(value))
		.map((value, key) => ({
			prefix: {
				[key]: ensurePrefixFilter(value)
			}
		}))
		.value();
}

function createWildcardFilters(filters) {
	return _.chain(filters)
		.omitBy((value, key) => isRecursiveFilter(key, value))
		.pickBy(value => isWildcardFilter(value))
		.map((value, key) => ({
			wildcard: {
				[key]: value.wildcard
			}
		}))
		.value();
}

function isNestedFilter(key) {
	return key[0] === '[' && key[key.length - 1] === ']';
}

function isRangeFilter(value) {
	return (
		!_.isArray(value) && 
		_.isObject(value) && 
		_.intersection(_.keys(value), ['lt', 'gt', 'lte', 'gte']).length
	);
}

function isPrefixFilter(value) {
	return value.prefix || isPrefixWildcard(value);
}

function isWildcardFilter(value) {
	return value.wildcard && !isPrefixWildcard(value);
}

function isPrefixWildcard(value) {
	if (!value.wildcard) {
		return false;
	} 

	const query = value.wildcard;

	for (let i = 0; i < query.length; i++) {
		if (query[i] === '*') {
			return i === query.length - 1;
		}
	}

	return false; 
}

function ensurePrefixFilter(value) {
	return value.prefix ? value.prefix : value.wildcard.slice(0, value.wildcard.length - 1);
}

export function createSorts(sorts = []) {
	const { plain = [], nested = [] } = categorizeSorts(sorts);

	return [
		...createSort(plain),
		...createNestedSorts(nested)
	];
}

function isNestedSort(sort) {
	const key = Object.keys(sort)[0];

	return key[0] === '[' && key[key.length - 1] === ']';
}

function categorizeSorts(sorts) {
	return sorts
		.reduce((acc, sort) => {
			if (isNestedSort(sort)) {
				const { nested = [] } = acc;

				return {
					...acc,
					nested: [ ...nested, sort ]
				};
			} else {
				const { plain = [] } = acc;

				return {
					...acc,
					plain: [ ...plain, sort ]
				};
			}
		}, {});
}

function createSort(sorts) {
	return sorts
		.map(sort => {
			const key = Object.keys(sort)[0];

			return {
				[key]: {
					order: sort[key]
				}
			};
		});
}

function createNestedSorts(nestedSorts) {
	return nestedSorts
		.map(nestedSort => {
			const key = Object.keys(nestedSort)[0];
			const property = key.slice(1, key.length - 1);
			const path = property.split('.')[0];
			const order = nestedSort[key];

			return {
				[property]: {
					order,
					nested_path: path
				}
			};
		});
}
