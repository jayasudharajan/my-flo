import _ from 'lodash';
import { client } from './elasticSearchProxy';
import { getWildcardSearchRequestSet } from './elasticSearchHelper';

class ElasticSearchUsers {

  constructor() {
    this.indexName = 'users';
  }

  scanAll(size=0, page=1) {
    size = parseInt(size) || 0;
    const from = (parseInt(page) - 1) * size;
    return client.search({
      index: this.indexName,
      from,
      size,
      body: {
        query: {
          match_all: {}
        }
      }
    });
  }

  search(match_string, size=0, page=1) {
    const setQuery = getWildcardSearchRequestSet(match_string, ['firstname', 'lastname', 'email']);
    size = parseInt(size) || 0;
    const from = (parseInt(page) - 1) * size;
    return client.search({
      index: this.indexName,
      from,
      size,
      body: {
        query: {
          bool: {
            should: setQuery
          }
        }
      }
    });
  }

  retrieveUserByGroup(group_id, size=0, page=1) {
    size = parseInt(size) || 0;
    const from = (parseInt(page) - 1) * size;
    return client.search({
      index: this.indexName,
      from,
      size,
      body: {
        query: {
          bool: {
            must: {
              term: {
                'account.group_id': group_id
              }
            }
          }
        }
      }
    });
  }

  searchUserInGroup(group_id, match_string, size=0, page=1) {
    const setQuery = getWildcardSearchRequestSet(match_string, ['firstname', 'lastname', 'email']);
    size = parseInt(size) || 0;
    const from = (parseInt(page) - 1) * size;
    return client.search({
      index: this.indexName,
      from,
      size,
      body: {
        query: {
          bool: {
            should: setQuery
          }
        },
        post_filter: {
          term: {
            'account.group_id': group_id
          }
        }
      }
    });
  }
}

export default ElasticSearchUsers;
