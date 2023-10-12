const _ = require('lodash');
const elasticsearch = require('elasticsearch');
const RandomDataGenerator = require('./RandomDataGenerator');

class ElasticsearchTestMixin {
	constructor(config, indexOptions) {
		this.elasticsearchClient = new elasticsearch.Client(config);
		this.indexOptions = indexOptions;
		this.randomDataGenerator = new RandomDataGenerator();
	}

	before(done) {
		const promises = _.map(
			this.indexOptions, 
			(schema, index) => 
				this.elasticsearchClient.indices.create({
					index,
					body: schema
				})
		);

		Promise.all(promises)
			.then(() => done())
			.catch(done);
	}

	after(done) {
		const promises = _.map(
			this.indexOptions,
			(options, index) =>
				this.elasticsearchClient.indices.delete({ index })
		);

		Promise.all(promises)
			.then(() => done())
			.catch(done);
	}

	populateDoctype(index, doctype, type, id) {
		const records = Array(10).fill(null)
			.map(() => this.randomDataGenerator.generate(type));

		return this.populateDoctypeWithData(index, doctype, records, id)
			.then(() => records);
	}

	populateDoctypeWithData(index, doctype, records, id = 'id') {
		const bulkIndex = _.flatMap(records, record => [
			{
				index: {
					_index: index,
					_type: doctype,
					_id: record[id]
				}
			},
			record
		]);

		return this.elasticsearchClient.bulk({ 
			refresh: true,
			body: bulkIndex
		})
		.then(result => {
			if (result.errors) {
				return Promise.reject(result);
			} else {
				return result;
			}
		});
	}

	clearDoctype(index, doctype, records, id = 'id') {
		const bulkDelete = _.flatMap(records, record => [
			{
				delete: {
					_index: index,
					_type: doctype,
					_id: record[id]
				}
			}
		]);

		return this.elasticsearchClient.bulk({ 
			refresh: true,
			body: bulkDelete 
		})
		.then(result => {
			if (result.errors) {
				return Promise.reject(result);
			} else {
				return result;
			}
		});
	}
}

module.exports = ElasticsearchTestMixin;