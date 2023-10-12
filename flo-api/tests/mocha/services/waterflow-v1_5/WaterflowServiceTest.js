// const _ = require('lodash');
// const chai = require('chai');
// const chaiAsPromised = require('chai-as-promised');
// const ICDSchema = require('../../../../dist/app/models/schemas/icdSchema');
// const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
// const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
// const LocationSchema = require('../../../../dist/app/models/schemas/locationSchema');
// const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
// const LocationService = require('../../../../dist/app/services/location-v1_5/LocationService');
// const WaterflowService = require('../../../../dist/app/services/waterflow-v1_5/WaterflowService');
// const TelemetryMeasurement = require('../../../../dist/app/services/waterflow-v1_5/models/TelemetryMeasurement');
// const TelemetryHourlyMeasurement = require('../../../../dist/app/services/waterflow-v1_5/models/TelemetryHourlyMeasurement');
// const Influx = require('influx');
// const AWS = require('aws-sdk');
// const inversify = require('inversify');
// const config = require('../../../../dist/config/config');
// const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
// const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');
// const redis = require('redis');
// require('reflect-metadata');
// const RandomDataGenerator = require('../../utils/RandomDataGenerator');
// const chance = require('chance')();
// const t = require('tcomb-validation');
// const tcustom =  require('../../../../dist/app/models/definitions/CustomTypes');
// const moment = require('moment-timezone');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const RedisTestMixin = require('../../utils/RedisTestMixin');
// const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');

// // ######################################################################

// const TPositiveNumber = t.refinement(t.Number, n => n >= 0);
// const TPositiveInteger = t.refinement(t.Integer, n => n >= 0);
// const TSystemMode = t.enums.of([2,3,5]);
// const TSwitch = t.enums.of([0,1]);
// const TZoneMode = t.refinement(t.Integer, n => n >= 1 && n <= 10);

// const TTelemetry = t.struct({
//   f: TPositiveNumber,
//   m: TPositiveInteger,
//   o: TPositiveInteger,
//   p: t.Number,
//   sm: TSystemMode,
//   sw1: TSwitch,
//   sw2: TSwitch,
//   t: t.Number,
//   wf: TPositiveInteger
// });

// const THourlyTelemetry = t.struct({
//   average_flowrate: TPositiveNumber,
//   average_pressure: t.Number,
//   average_temperature: t.Number,
//   total_flow: TPositiveNumber
// });

// const customGenerators = [
//   {
//     type: TPositiveInteger,
//     generator: () => chance.integer({ min: 0 })
//   },
//   {
//     type: TPositiveNumber,
//     generator: () => chance.floating({ min: 0 })
//   },
//   {
//     type: TZoneMode,
//     generator: () => chance.integer({ min: 1, max: 10 })
//   }
// ];

// // ######################################################################

// const influxDbClient = new Influx.InfluxDB({
//   host: '127.0.0.1',
//   port: 8086,
//   database: 'telemetry'
// });

// const influxDbAnalyticsClient = new Influx.InfluxDB({
//   host: '127.0.0.1',
//   port: 8086,
//   database: 'telemetry_analytics'
// });

// const now = moment();
// const telemetryMeasurement = 'telemetry_' + now.format('YYYYMM');
// const hourlyTelemetryMeasurement = 'telemetry_hourly';
// const randomDataGenerator = new RandomDataGenerator(customGenerators);
// const redisTestMixin = new RedisTestMixin();
// const dynamodbTestMixin = new DynamoDbTestMixin(config.aws.dynamodb.endpoint, [ICDSchema, LocationSchema], config.aws.dynamodb.prefix)

// describeWithMixins('WaterflowService', [dynamodbTestMixin, redisTestMixin], function () {
//   this.timeout(60000);
//   chai.should();
//   chai.use(chaiAsPromised);

//   // Declare bindings
//   const container = new inversify.Container();
//   container.bind(ICDTable).to(ICDTable);
//   container.bind(ICDService).to(ICDService);
//   container.bind(LocationTable).to(LocationTable);
//   container.bind(LocationService).to(LocationService);
//   container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamodbTestMixin.getDynamoDbDocumentClient());
//   container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));
//   container.bind(redis.RedisClient).toConstantValue(redisTestMixin.redisClient);
//   container.bind(TelemetryMeasurement).to(TelemetryMeasurement);
//   container.bind(TelemetryHourlyMeasurement).to(TelemetryHourlyMeasurement);
//   container.bind(WaterflowService).to(WaterflowService);
//   container.bind(Influx.InfluxDB).toConstantValue(influxDbClient).whenTargetIsDefault();
//   container.bind(Influx.InfluxDB).toConstantValue(influxDbAnalyticsClient).whenTargetNamed('Analytics');
//   // Resolve dependencies
//   const icdTable = container.get(ICDTable);
//   const locationTable = container.get(LocationTable);
//   const service = container.get(WaterflowService);

//   before(function (done) {
//     Promise.all([
//       influxDbClient.createDatabase('telemetry'),
//       influxDbClient.createDatabase('telemetry_analytics'),
//     ])
//       .then(() => done())
//       .catch(done);
//   });

//   after(function (done) {
//     Promise.all([
//       influxDbClient.dropDatabase('telemetry'),
//       influxDbClient.dropDatabase('telemetry_analytics')
//     ])
//       .then(() => done())
//       .catch(done);
//   });

//   beforeEach(function (done)  {
//     this.currentTest.location = Object.assign(
//       randomDataGenerator.generate(locationTable.getType()),
//       { timezone: moment.tz.guess() }
//     );
//     this.currentTest.icd1 = Object.assign(
//       randomDataGenerator.generate(icdTable.getType()),
//       { location_id: this.currentTest.location.location_id }
//     );
//     this.currentTest.icd2 = Object.assign(
//       randomDataGenerator.generate(icdTable.getType()),
//       { location_id: this.currentTest.location.location_id }
//     );
//     this.currentTest.telemetry1 = generateData(100, TTelemetry);
//     this.currentTest.telemetry2 = generateData(100, TTelemetry);
//     this.currentTest.hourlyTelemetry1 = generateData(100, THourlyTelemetry);
//     this.currentTest.hourlyTelemetry2 = generateData(100, THourlyTelemetry);

//     Promise.all([
//       locationTable.create(this.currentTest.location),
//       icdTable.create(this.currentTest.icd1),
//       icdTable.create(this.currentTest.icd2),
//       insertData(influxDbClient, this.currentTest.icd1.device_id, telemetryMeasurement, 'seconds', this.currentTest.telemetry1),
//       insertData(influxDbClient, this.currentTest.icd2.device_id, telemetryMeasurement, 'seconds', this.currentTest.telemetry2),
//       insertData(influxDbAnalyticsClient, this.currentTest.icd1.device_id, hourlyTelemetryMeasurement, 'hours', this.currentTest.hourlyTelemetry1),
//       insertData(influxDbAnalyticsClient, this.currentTest.icd2.device_id, hourlyTelemetryMeasurement, 'hours', this.currentTest.hourlyTelemetry2)
//     ])
//       .then(() => done())
//       .catch(done);
//   });

//   afterEach(function (done) {
//     Promise.all([
//       influxDbClient.dropMeasurement(telemetryMeasurement),
//       influxDbClient.dropMeasurement(hourlyTelemetryMeasurement)
//     ])
//       .then(() => done())
//       .catch(done);
//   });

//   describe('#retrieveDailyWaterFlow', function () {
//     it('should retrieve 24 hours of total flow', function (done) {
//       service.retrieveDailyWaterFlow(this.test.icd1.device_id, this.test.location.timezone)
//         .should.eventually.have.lengthOf(24)
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyWaterFlowByDeviceId', function () {
//     it('should retrieve 24 hours of total flow', function (done) {
//       service.retrieveDailyWaterFlowByDeviceId(this.test.icd1.device_id)
//         .should.eventually.have.lengthOf(24)
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyWaterFlowByLocationId', function () {
//     it('should retrieve 24 hours of total flow', function (done) {
//       service.retrieveDailyWaterFlowByLocationId(this.test.location.location_id)
//         .should.eventually.have.lengthOf(24)
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyWaterFlowByICDId', function () {
//     it('should retrieve 24 hours of total flow', function (done) {
//       service.retrieveDailyWaterFlowByICDId(this.test.icd1.id)
//         .should.eventually.have.lengthOf(24)
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyTotalWaterFlow', function() {
//     it('should retrieve the total daily water flow', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(2); 

//       service.retrieveDailyTotalWaterFlow(this.test.icd1.device_id, this.test.location.timezone)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyTotalWaterFlowByDeviceId', function() {
//     it('should retrieve the total daily water flow', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(2); 

//       service.retrieveDailyTotalWaterFlowByDeviceId(this.test.icd1.device_id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyTotalWaterFlowByLocationId', function() {
//     it('should retrieve the total daily water flow', function (done) {
//       const expectedUsage = _.chain(_.zip(this.test.telemetry1, this.test.telemetry2))
//           .map(second => _.sumBy(second, 'f'))
//           .sum()
//           .value()
//           .toFixed(2);

//       service.retrieveDailyTotalWaterFlowByLocationId(this.test.location.location_id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveDailyTotalWaterFlowByICDId', function() {
//     it('should retrieve the total daily water flow', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(2); 

//       service.retrieveDailyTotalWaterFlowByICDId(this.test.icd1.id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveMonthlyUsage', function() {
//     it('should retrieve monthly water usage', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(10);

//       service.retrieveMonthlyUsage(this.test.icd1.device_id, this.test.location.timezone)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveMonthlyUsageByDeviceId', function() {
//     it('should retrieve monthly water usage', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(10);

//       service.retrieveMonthlyUsageByDeviceId(this.test.icd1.device_id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveMonthlyUsageByLocationId', function() {
//     it('should retrieve monthly water usage', function (done) {
//       const expectedUsage = _.chain(_.zip(this.test.telemetry1, this.test.telemetry2))
//         .map(second => _.sumBy(second, 'f'))
//         .sum()
//         .value()
//         .toFixed(10);

//       service.retrieveMonthlyUsageByLocationId(this.test.location.location_id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveMonthlyUsageByICDId', function() {
//     it('should retrieve the total daily water flow', function (done) {
//       const expectedUsage = _.sumBy(this.test.telemetry1, 'f').toFixed(2); 

//       service.retrieveMonthlyUsageByICDId(this.test.icd1.id)
//         .then(({ usage }) => Math.round(usage))
//         .should.eventually.be.within(Math.floor(expectedUsage), Math.ceil(expectedUsage))
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HoursConsumption', function() {
//     it('should return 24 hours of data', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData = getExpected24HourData(this.test.hourlyTelemetry1);

//       service.retrieveLast24HoursConsumption(this.test.icd1.device_id, fromTime)
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .deep.equal(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HoursConsumptionByLocationId', function() {
//     it('should return 24 hours of data', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData1 = getExpected24HourData(this.test.hourlyTelemetry1);
//       const expectedData2 = getExpected24HourData(this.test.hourlyTelemetry2);
//       const expectedData = _.zip(expectedData1, expectedData2).map(hour => _.sum(hour));

//       service.retrieveLast24HoursConsumptionByLocationId(this.test.location.location_id, fromTime)
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .deep.equal(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HoursConsumptionByICDId', function() {
//     it('should return 24 hours of data', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData = getExpected24HourData(this.test.hourlyTelemetry1);

//       service.retrieveLast24HoursConsumptionByICDId(this.test.icd1.id, fromTime)
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .deep.equal(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast30DaysConsumption', function () {
//     it('should return 30 days of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(30 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMMDD');

//       service.retrieveLast30DaysConsumption(this.test.icd1.device_id, fromTime, this.test.location.timezone)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(30)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast30DaysConsumptionByDeviceId', function () {
//     it('should return 30 days of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(30 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMMDD');

//       service.retrieveLast30DaysConsumptionByDeviceId(this.test.icd1.device_id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(30)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast30DaysConsumptionByLocationId', function () {
//     it('should return 30 days of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(30 * 24);
//       const expectedData1 = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMMDD', true);
//       const expectedData2 = getExpectedData(this.test.hourlyTelemetry2, this.test.location.timezone, 'YYYYMMDD', true);
//       const expectedData = _.zip(expectedData1, expectedData2).map(hour => Math.round(_.sum(hour)));
      
//       service.retrieveLast30DaysConsumptionByLocationId(this.test.location.location_id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(30)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast30DaysConsumptionByICDId', function () {
//     it('should return 30 days of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(30 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMMDD');

//       service.retrieveLast30DaysConsumptionByICDId(this.test.icd1.id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(30)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast12MonthsConsumption', function () {
//     it('should return 12 months of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(365 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMM');

//       service.retrieveLast12MonthsConsumption(this.test.icd1.device_id, fromTime, this.test.location.timezone)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(12)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast12MonthsConsumptionByDeviceId', function () {
//     it('should return 12 months of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(365 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMM');

//       service.retrieveLast12MonthsConsumptionByDeviceId(this.test.icd1.device_id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(12)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast12MonthsConsumptionByLocationId', function () {
//     it('should return 12 months of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(365 * 24);
//       const expectedData1 = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMM', true);
//       const expectedData2 = getExpectedData(this.test.hourlyTelemetry2, this.test.location.timezone, 'YYYYMM', true);
//       const expectedData = _.zip(expectedData1, expectedData2).map(hour => Math.round(_.sum(hour)));
      
//       service.retrieveLast12MonthsConsumptionByLocationId(this.test.location.location_id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(12)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast12MonthsConsumptionByICDId', function () {
//     it('should return 12 months of data', function (done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(365 * 24);
//       const expectedData = getExpectedData(this.test.hourlyTelemetry1, this.test.location.timezone, 'YYYYMM');

//       service.retrieveLast12MonthsConsumptionByICDId(this.test.icd1.id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: result.data.map(datum => Math.round(datum))
//             }
//           );
//         })
//         .should.eventually
//           .include({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime
//           })
//           .and.have.property('data')
//             .with.lengthOf(12)
//             .and
//             .deep.include.members(expectedData)
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HourlyAverages', function () {
//     it('should retrieve last 24 hours of averages', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData = getExpected24HourAverages(this.test.hourlyTelemetry1);
      
//       service.retrieveLast24HourlyAverages(this.test.icd1.device_id, fromTime)
//         .should.eventually
//           .deep.equal({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime,
//             data: expectedData
//           })
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HourlyAveragesByLocationId', function () {
//     it('should retrieve last 24 hours of averages', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData1 = getExpected24HourAverages(this.test.hourlyTelemetry1);
//       const expectedData2 = getExpected24HourAverages(this.test.hourlyTelemetry2);
//       const expectedData = {
//           pressure: _.zip(expectedData1.pressure, expectedData2.pressure).map(hour => Math.round(_.sum(hour))),
//           flow_rate: _.zip(expectedData1.flow_rate, expectedData2.flow_rate).map(hour => Math.round(_.sum(hour))),
//           temperature: _.zip(expectedData1.temperature, expectedData2.temperature).map(hour => Math.round(_.sum(hour)))
//       };
    
//       service.retrieveLast24HourlyAveragesByLocationId(this.test.location.location_id, fromTime)
//         .then(result => {
//           return Object.assign(
//             result,
//             {
//               data: _.mapValues(result.data, averages => averages.map(Math.round))
//             }
//           );
//         })
//         .should.eventually
//           .deep.equal({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime,
//             data: expectedData
//           })
//         .notify(done);
//     });
//   });

//   describe('#retrieveLast24HourlyAveragesByICDId', function () {
//     it('should retrieve last 24 hours of averages', function(done) {
//       const { fromTime, expectedStartTime, expectedEndTime } = getExpectedTimes(24);
//       const expectedData = getExpected24HourAverages(this.test.hourlyTelemetry1);

//       service.retrieveLast24HourlyAveragesByICDId(this.test.icd1.id, fromTime)
//         .should.eventually
//           .deep.equal({
//             start_time: expectedStartTime,
//             end_time: expectedEndTime,
//             data: expectedData
//           })
//         .notify(done);
//     });
//   });
// });

// function insertData(influxDbClient, deviceId, measurement, units, data) {
//   const points = data
//     .map((dataPoint, i) => ({
//       tags: { did: deviceId },
//       fields: dataPoint,
//       timestamp: moment(now).subtract(i, units).toDate()
//     }));

//   const promises = _.chunk(points, 100)
//     .map(telemetryChunk => influxDbClient.writeMeasurement(
//       measurement,
//       points, 
//       { database: influxDbClient.options.database }
//     ));


//   return Promise.all(promises);
// }

// function generateData(numRecords, type) {
//   return Array(numRecords).fill(null)
//     .map(() => randomDataGenerator.generate(type));
// }

// function getExpectedTimes(numHours) {
//   const fromTime = now.toDate().getTime();
//   const expectedEndTime = moment(fromTime).subtract(1, 'hours').endOf('hour').toISOString();
//   const expectedStartTime = moment(expectedEndTime).subtract(numHours, 'hours').startOf('hour').toISOString();

//   return {
//     fromTime,
//     expectedStartTime,
//     expectedEndTime
//   };
// }

// function getExpected24HourData(hourlyTelemetry) {
//   return _.map(hourlyTelemetry, 'total_flow')
//     .slice(1, 25)
//     .reverse();
// }

// function getExpectedData(hourlyTelemetry, timezone, format, noRounding) {
//   return _.chain(hourlyTelemetry)
//     .slice(1)
//     .map((data, i) => ({ 
//       time: moment(now).subtract(i + 1, 'hours').tz(timezone).format(format), 
//       data 
//     }))
//     .groupBy('time')
//     .map((data, time) => ({ 
//       time, 
//       data: (!noRounding ? Math.round : x => x)(
//         _.chain(data).flatMap('data').sumBy('total_flow').value()
//       ) 
//     }))
//     .sortBy('time')
//     .map('data')
//     .value();
// }

// function getExpected24HourAverages(hourlyTelemetry) {
//   const last24Hours = hourlyTelemetry.slice(1, 25).reverse();

//   return {
//     flow_rate: _.map(last24Hours, 'average_flowrate'),
//     pressure: _.map(last24Hours, 'average_pressure'),
//     temperature: _.map(last24Hours, 'average_temperature')
//   };
// }

