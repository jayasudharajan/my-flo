const stockICDTableSchema = require('../../../../../dist/app/models/schemas/stockICDSchema');
const deviceSerialNumberSchema = require('../../../../../dist/app/models/schemas/DeviceSerialNumberSchema');
const deviceSerialNumberCounterSchema = require('../../../../../dist/app/models/schemas/DeviceSerialNumberCounterSchema');

module.exports = [
  stockICDTableSchema,
  deviceSerialNumberSchema,
  deviceSerialNumberCounterSchema
];
