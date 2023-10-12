/**
 * Created by Francisco on 3/27/2017.
 */
import moment from 'moment'
import _ from 'lodash';

/**
 * Do to the set up of the APi project, we are dropping JS object properties that start with an underscore '_' from
 * API responses, since Elastic Search responses contain properties names that start with '_' we need to map them to
 * to a new object. This also sanitizes the data and removes excessive properties, keeping responses leaner.
 * */
export function makeAggregationResponsePretty(esResponse) {
    return {
        total: esResponse.hits.total,
        items: esResponse.hits.hits.map(item => item._source),
        aggregations: esResponse.aggregations
    }
}

export function makeSearchResponse(esResponse) {
    return {
        total: esResponse.hits.total,
        items: esResponse.hits.hits.map(item => item._source)
    };
}

/**
 * This method will return the names of the indices that will need to be queried based on the date range.
 * To learn more about hour log indices read:
 * https://flotechnologies.atlassian.net/wiki/display/FLO/Querying+logs+like+a+boss
 * */
export function getLogIndicesNamesByDateRange(fromDate, toDate, logName) {
    isToDateGreaterThanFromDate(fromDate, toDate); //validation check

    if (moment(fromDate).isSame(toDate, 'month')) { // same month no need to do Date math this method takes year into consideration too.
        return [generateIndexName(logName, fromDate)];
    }
    return generateIndexNames(fromDate, toDate, logName);
}

/**
 * Given a from and to date in YYYY-MM format and the index name, it will generate a array with all the indices that
 * need to be queried, it will throw an exception error otherwise.
 * */
function generateIndexNames(fromDate, toDate, indexName) {
    const numMonths = moment(toDate).startOf('month').diff(moment(fromDate).startOf('month'), 'months') + 1;

    return new Array(numMonths).fill(null)
        .map((emptyData, i) => moment(fromDate).add(i, 'months'))
        .map(date => generateIndexName(indexName,date));
}

function generateIndexName(indexName, date) {
    return indexName + '-' + moment.utc(date).format('YYYY-MM')
}

function isToDateGreaterThanFromDate(fromDate, toDate) {

    if (moment.utc(toDate).isBefore(fromDate)) {
        throw 'toDate cannot be before fromDate';
    }
    return true;
}

/**
 * Generate wildcard search request set
 */
export function getWildcardSearchRequestSet(match_string, fields) {
    return _.chain(match_string)
            .toLower()
            .split(' ')
            .flatMap(match_phrase => {
                return match_phrase? _.map(fields, field => {
                    if(field.indexOf('.') < 0) {
                        return getWildcardTokenSet(field, match_phrase);
                    } else {
                        return { nested: {
                            path: _.chain(field).split('.').dropRight().join('.').value(),
                            query: getWildcardTokenSet(field, match_phrase)
                        }};
                    }
                }): [];
            })
            .value();
}

export function getWildcardTokenSet(field, match_phrase) {
    return { bool: { must: _.map(('*' + match_phrase + '*').split(/[,@\+\-]+/), token => {
        return { wildcard: { [field]: token } };
    }) } };
}
