const _ = require('lodash');
const icdSchema = require('../../../../../dist/app/models/schemas/icdSchema');
const onboardingLogSchema = require('../../../../../dist/app/models/schemas/OnboardingLogSchema');

module.exports = [onboardingLogSchema, icdSchema];