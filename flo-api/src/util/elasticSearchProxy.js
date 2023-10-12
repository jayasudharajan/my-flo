/**
 * Created by Francisco on 3/23/2017.
 */
import config from '../config/config';
import elasticsearch from 'elasticsearch';

/**
 * NOTE: using most;y default configuration values, see full configuration options here:
 * https://www.elastic.co/guide/en/elasticsearch/client/javascript-api/current/configuration.html
 * */
export const client = new elasticsearch.Client({
    host: config.elasticSearchHost,
    log: [{
        type: 'stdio',
        levels: ['error', 'warning']
    }]
});


/** search params ---
 from: (pgNumber - 1) * size,
 size: size,
 index: indexName,
 type: typeName,
 body : query
 * */

/**
 * Will execute GET DSL query against the ES cluster
 * see https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
 * https://www.elastic.co/guide/en/elasticsearch/client/javascript-api/current/quick-start.html#_say_hello_to_elasticsearch
 * */
export function getDSLQuery(searchParams) {
    return client.search(searchParams);
}


