export const USATimezone = [
  "America/Anchorage",
  "America/Port_of_Spain",
  "America/Chicago",
  "America/New_York",
  "Pacific/Honolulu",
  "America/Phoenix",
  "America/Los_Angeles",
  "US/Pacific" // Temporary?
];

export const USATimezoneShort = [
  "AKST",
  "AST",
  "CST",
  "EST",
  "HAST",
  "MST",
  "PST"
];

export const USAState = [
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY'
];

export const australiaState = [
  'NSW',
  'QLD',
  'SA',
  'TAS',
  'VIC',
  'WA',
  'ACT',
  'JBT',
  'NT'
];

export const germanyState = [
  'BW',
  'BY',
  'BE',
  'BB',
  'HB',
  'HH',
  'HE',
  'NI',
  'MV',
  'NW',
  'RP',
  'SL',
  'SN',
  'ST',
  'SH',
  'TH'
];

export const ukState = [
  'UK'
];

export const countries = {
  USA: 'US',
  Australia: 'AU',
  Germany: 'DE',
  UK: 'UK'
};

export const errorTypes = {
  ICD_NOT_FOUND: {
    status: 404,
    message: 'Device not found.'
  },
  ALARM_DELIVERY_FILTER_NOT_FOUND: {
    status: 404,
    message: 'AlarmNotificationDeliveryFilter not found.'
  },
  ICD_ALARM_INCIDENT_REGISTRY_NOT_FOUND: {
    status: 404,
    message: 'ICDAlarmIncidentRegistry not found.'
  },
  LOCATION_NOT_FOUND: {
    status: 404,
    message: 'Location not found.'
  },
  USER_TOKEN_NOT_FOUND: {
    status: 404,
    message: 'UserToken not found.'
  },
  USER_NOT_FOUND: {
    status: 404,
    message: 'User not found.'
  },
  UNAUTHORIZED_ACCESS: {
    status: 403,
    message: 'Unauthorized access.'
  }
};