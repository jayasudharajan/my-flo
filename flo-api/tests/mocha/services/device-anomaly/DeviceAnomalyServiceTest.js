const _ = require('lodash');
const AWS = require('aws-sdk');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const DeviceAnomalyService = require('../../../../dist/app/services/device-anomaly/DeviceAnomalyService');
const DeviceAnomalyEventTable = require('../../../../dist/app/services/device-anomaly/DeviceAnomalyEventTable');
const TDeviceAnomaly = require('../../../../dist/app/services/device-anomaly/models/TDeviceAnomaly');
require('reflect-metadata');

const moment = require('moment');
const tableTestUtils = require('../../utils/tableTestUtils');


const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('DeviceAnomalyServiceTest', [dynamoDbTestMixin], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(DeviceAnomalyService);
  const table = container.get(DeviceAnomalyEventTable);

  describe('#handleEvent', function () {
    it('should create a record', function (done) {
      const alert = {
        "id": "No Flow Alert:did=f87aef010b62",
        "message": "did=f87aef010b62 reported *5.7138608333333325* gal in the last 6h",
        "details": "{&#34;Name&#34;:&#34;downsampled_telemetry&#34;,&#34;TaskName&#34;:&#34;API_POStTEST_3&#34;,&#34;Group&#34;:&#34;did=f87aef010b62&#34;,&#34;Tags&#34;:{&#34;did&#34;:&#34;f87aef010b62&#34;},&#34;ServerInfo&#34;:{&#34;Hostname&#34;:&#34;prod-da662558-us-east-1-kapa-6.influxdata.local&#34;,&#34;ClusterID&#34;:&#34;018e2ad5-5b0d-488c-88a3-3b5db42d2747&#34;,&#34;ServerID&#34;:&#34;910ce708-5442-4eeb-bc3b-291a98cfff5a&#34;},&#34;ID&#34;:&#34;No Flow Alert:did=f87aef010b62&#34;,&#34;Fields&#34;:{&#34;total_gallons&#34;:5.7138608333333325},&#34;Level&#34;:&#34;CRITICAL&#34;,&#34;Time&#34;:&#34;2018-05-11T14:58:06.390633447Z&#34;,&#34;Duration&#34;:85157853446708,&#34;Message&#34;:&#34;did=f87aef010b62 reported *5.7138608333333325* gal in the last 6h&#34;}\n",
        "time": "2018-05-11T14:58:06.390633447Z",
        "duration": 85157853446708,
        "level": "CRITICAL",
        "data": {
          "series": [
            {
              "name": "downsampled_telemetry",
              "tags": {
                "did": "f87aef010b62"
              },
              "columns": [
                "time",
                "total_gallons"
              ],
              "values": [
                [
                  "2018-05-11T14:58:06.390633447Z",
                  5.7138608333333325
                ]
              ]
            }
          ]
        },
        "previousLevel": "CRITICAL"
      };
      const type = TDeviceAnomaly.NO_FLOW_24H;
      const values = {};
      const expected = {
        name: 'downsampled_telemetry',
        type: parseInt(TDeviceAnomaly.NO_FLOW_24H),
        device_id: 'f87aef010b62',
        level: 'CRITICAL',
        time: '2018-05-11T14:58:06.390633447Z',
        duration: 85157853446708,
        message: 'did=f87aef010b62 reported *5.7138608333333325* gal in the last 6h',
        total_gallons: 5.7138608333333325,
      };

      service.handleEvent(parseInt(type), alert, values)
        .then(() => table.retrieve({device_id: expected.device_id, time: expected.time}))
        .should.eventually.have.property('Item').deep.equal(expected)
        .notify(done);
    });
  });

  describe('#retrieveByTypeAndDateRange', function () {
    it('should retrieve anomaly records', function (done) {
      const now = moment();
      const type = TDeviceAnomaly.NO_FLOW_24H;
      const startDate = moment(now).subtract(1, 'days').toISOString();
      const endDate = moment(now).add(1, 'days').toISOString();
      const anomaly10DaysOld = Object.assign(
        getDeviceAnomaly(),
        {
          time: moment(now).subtract(10, 'days').toISOString(),
          type: 1
        }
      );
      const anomaly5hoursOld = Object.assign(
        getDeviceAnomaly(),
        {
          time: moment(now).subtract(5, 'hours').toISOString(),
          type: 1
        }
      );
      const anomaly3DaysOld = Object.assign(
        getDeviceAnomaly(),
        {
          time: moment(now).subtract(3, 'days').toISOString(),
          type: 1
        }
      );
      Promise.all(
        [anomaly10DaysOld, anomaly5hoursOld, anomaly3DaysOld]
          .map(record => table.create(record))
      )
        .then(() => service.retrieveByTypeAndDateRange(parseInt(type), startDate, endDate))
        .then(results => results[0])
        .should.eventually.deep.equal(anomaly5hoursOld)
        .notify(done);

    });
  });

  function generateDeviceAnomalyRequest() {
    return {
      "id": "No Flow Alert:did=f87aef010b62",
      "message": "did=f87aef010b62 reported *5.7138608333333325* gal in the last 6h",
      "details": "{&#34;Name&#34;:&#34;downsampled_telemetry&#34;,&#34;TaskName&#34;:&#34;API_POStTEST_3&#34;,&#34;Group&#34;:&#34;did=f87aef010b62&#34;,&#34;Tags&#34;:{&#34;did&#34;:&#34;f87aef010b62&#34;},&#34;ServerInfo&#34;:{&#34;Hostname&#34;:&#34;prod-da662558-us-east-1-kapa-6.influxdata.local&#34;,&#34;ClusterID&#34;:&#34;018e2ad5-5b0d-488c-88a3-3b5db42d2747&#34;,&#34;ServerID&#34;:&#34;910ce708-5442-4eeb-bc3b-291a98cfff5a&#34;},&#34;ID&#34;:&#34;No Flow Alert:did=f87aef010b62&#34;,&#34;Fields&#34;:{&#34;total_gallons&#34;:5.7138608333333325},&#34;Level&#34;:&#34;CRITICAL&#34;,&#34;Time&#34;:&#34;2018-05-11T14:58:06.390633447Z&#34;,&#34;Duration&#34;:85157853446708,&#34;Message&#34;:&#34;did=f87aef010b62 reported *5.7138608333333325* gal in the last 6h&#34;}\n",
      "time": "2018-05-11T14:58:06.390633447Z",
      "duration": 85157853446708,
      "level": "CRITICAL",
      "data": {
        "series": [
          {
            "name": "downsampled_telemetry",
            "tags": {
              "did": "f87aef010b62"
            },
            "columns": [
              "time",
              "total_gallons"
            ],
            "values": [
              [
                "2018-05-11T14:58:06.390633447Z",
                5.7138608333333325
              ]
            ]
          }
        ]
      },
      "previousLevel": "CRITICAL"
    };
  }


  function getDeviceAnomaly() {
    return tableTestUtils.generateRecord(table)
  }

}); 