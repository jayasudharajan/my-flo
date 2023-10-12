import _ from 'lodash';
import elasticsearch from 'elasticsearch';
import ElasticsearchIndex from '../utils/ElasticsearchIndex';
import DIFactory from  '../../../util/DIFactory';

class UsersIndex extends ElasticsearchIndex {
	constructor(elasticsearchClient) {
		super('users', elasticsearchClient);
	}

	retrieveByUserId(userId) {
		return this.retrieve('user', userId);
	}

	_createMatchQuery(query) {
		return {
			must: [
				{
					multi_match: {
						query,
						fields: ['firstname', 'lastname',  'email'],
						type: 'cross_fields',
						operator: 'and'
					}
				}
			]
		};
	}
}

export default DIFactory(UsersIndex, [elasticsearch.Client]);