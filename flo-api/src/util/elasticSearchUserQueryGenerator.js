/**
 * Created by Francisco on 3/24/2017.
 */

/**
 * This function creates the the query for elastic search, it is an aggregation by default of active users who are
 * not system users. Takes Boolean parameters in case it is needed to return the aggregation of un-active users
 * or included system users.
 * Size: 0 by default if an integer is pass it will return that number of type items found inside the query result
 * and are included in the aggregation calculation, if 0 the elastic search response will include only the aggregation
 * results otherwise.
 * */
export function getUserCountByAccountGroupIDQuery(size = 0, activeUser = true, includeSystemUsers = false, pgNumber = null) {
    return {
        index: "users",
        size: size,
        from: pgNumber === undefined ? 0 : (pageNumber - 1) * size,
        body: {
            query: {
                bool: {
                    filter: [
                        {
                            term: {
                                is_system_user: includeSystemUsers
                            }
                        },
                        {
                            term: {
                                is_active: activeUser
                            }
                        }
                    ]
                }
            },
            aggs: {
                users_by_group: {
                    terms: {
                        field: "account.group_id"
                    }
                }
            }

        }
    };
}
