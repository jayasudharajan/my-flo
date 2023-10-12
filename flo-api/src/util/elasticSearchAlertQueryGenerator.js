/**
 * Created by Francisco on 3/30/2017.
 */

export function getAlertOccuranceByIDAndDateRangeQuery(indicesNames, dateFrom, dateTo, alarmId, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                        {
                            term: {
                                alarm_id: alarmId
                            }
                        }
                    ]
                }
            }
        }
    };
}

export function getAlertOccuranceByIDAndDateRangeQueryAndIcdIdQuery(indicesNames, dateFrom, dateTo, alarmId, size, pageNumber, icdId) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                        {
                            term: {
                                alarm_id: alarmId
                            }
                        },
                        {
                            term: {
                                icd_id: icdId
                            }
                        }
                    ]
                }
            }
        }
    };
}

export function getAlertsWeeklyHistogramBySeverityAggregationQuery(indicesNames, dateFrom, dateTo, severity, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                        {
                            term: {
                                severity: severity
                            }
                        }
                    ]
                }
            },
            aggs: {
                alarm_count_by_week: {
                    date_histogram: {
                        field: "updated_at",
                        interval: "week",
                        format: "yyyy-MM-dd"
                    }

                }
            }
        }
    };
}

export function getAlertsOverDateRangeBySeverityAggregationQuery(indicesNames, dateFrom, dateTo, severity, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                        {
                            term: {
                                severity: severity
                            }
                        }
                    ]
                }
            },
            aggs: {
                daily_alarm_count_by_severity: {
                    value_count: {
                        field: "updated_at"
                    }

                }
            }
        }
    };
}


export function getNewestAlertsQuery(indicesNames, dateFrom, dateTo, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                    ]
                }
            },
        }
    };
}
export function getNewestAlertByIcdIdQuery(indicesNames, icdId, dateFrom, dateTo, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                icd_id: icdId
                            }
                        },
                    ]
                }
            },
        }
    };
}

export function getDailyAlertsOverDateRangeBySeverityAggregationQuery(indicesNames, severity, dateFrom, dateTo, size, pageNumber) {
    return {
        index: indicesNames,
        type: 'alarmnotificationdeliveryfilterlog',
        size: size,
        from: pageNumber === undefined ? 0 : (pageNumber - 1) * size,
        ignore_unavailable: true,
        body: {
            sort: [
                {updated_at: {"order": "desc"}}
            ],
            query: {
                bool: {
                    filter: [
                        {
                            range: {
                                updated_at: {
                                    gte: dateFrom,
                                    lt: dateTo
                                }
                            }
                        },
                        {
                            term: {
                                status: 3
                            }
                        },
                        {
                            term: {
                                severity: severity
                            }
                        }
                    ]
                }
            },
            aggs: {
                alarm_count_by_day: {
                    date_histogram: {
                        field: "updated_at",
                        interval: "day",
                        format: "yyyy-MM-dd"
                    }

                }
            }
        }
    };
}
