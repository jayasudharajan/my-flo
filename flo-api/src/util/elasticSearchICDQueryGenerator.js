export function getICDsByTimezone(timezone, size, pg = null) {
    return {
        index: 'icds',
        type: 'icd',
        size,
        from: !pg ? undefined : Math.max(pg - 1, 0) * size,
        body: {
            query: {
                term: {
                    'geo_location.timezone': timezone
                }
            }
        }
    };
}