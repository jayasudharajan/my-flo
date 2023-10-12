import moment from 'moment';
import ElasticsearchIndex from './ElasticsearchIndex';
import NotFoundException from './exceptions/NotFoundException';

export default class ElasticsearchMonthlyLogIndex extends ElasticsearchIndex {
	constructor(indexName, elasticsearchClient) {
		super(indexName, elasticsearchClient);
	}

	retrieveAll(startDate, endDate, options) {
		const indexNames = this._getIndexNames(startDate, endDate);

		return super._retrieveAll(indexNames, options);
	}

	retrieve(startDate, endDate, doctype, id) {
		const indexNames = this._getIndexNames(startDate, endDate);
		const promises = indexNames
			.reverse()
			.map(indexName => 
				super._retrieve(indexName, doctype, id)
					.catch(err => {
						if (err.name === 'NotFoundException') {
							return null;
						} else {
							throw err;
						}
					})
			);

		return Promise.all(promises)
			.then(results => {
				const result = results.filter(result => result && result.total)[0];

				if (!result) {
					throw new NotFoundException(`${ doctype } not found`);
				} else {
					return result;
				}
			});
	}

	_getIndexNames(startDate, endDate) {
		const numMonthsBetweenDates = 1 + Math.abs(moment(endDate).startOf('month').diff(moment(startDate).startOf('month'), 'months'));

		return Array(numMonthsBetweenDates).fill(null)
			.map((emptyData, i) => moment(startDate).add(i, 'months'))
			.map(date => `${ this.indexName }-${ date.format('YYYY-MM') }`);
	}
}