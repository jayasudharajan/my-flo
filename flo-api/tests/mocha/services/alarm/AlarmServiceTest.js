// const _ = require('lodash');
// const chai = require('chai');
// const chaiAsPromised = require('chai-as-promised');
// const inversify = require('inversify');
// const elasticsearch = require('elasticsearch');
// const RandomDataGenerator = require('../../utils/RandomDataGenerator');
// const config = require('../../../../dist/config/config');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const AlarmService = require('../../../../dist/app/services/alarm/AlarmService');
// const ICDAlarmIncidentRegistriesIndex = require('../../../../dist/app/services/alarm/ICDAlarmIncidentRegistriesIndex');
// const ICDAlarmIncidentRegistriesMappings = require('../../../../dist/app/services/alarm/models/mappings/icdalarmincidentregistries');
// const TICDAlarmIncidentRegistryDoc = require('../../../../dist/app/services/alarm/models/TICDAlarmIncidentRegistryDoc');
// const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
// const ElasticsearchTestMixin = require('../../utils/ElasticsearchTestMixin');
// const moment = require('moment');

// require('reflect-metadata');

// const month1 = moment().startOf('month');
// const month2 = moment(month1).subtract(1, 'months').startOf('month');
// const index1 = 'icdalarmincidentregistries-' + month1.format('YYYY-MM');
// const index2 = 'icdalarmincidentregistries-' + month2.format('YYYY-MM');

// const randomDataGenerator = new RandomDataGenerator();
// const elasticsearchTestMixin = new ElasticsearchTestMixin(
// 	{ host: config.elasticSearchHost },
// 	{
// 		[index1]: { 
// 			mappings: ICDAlarmIncidentRegistriesMappings 
// 		},
// 		[index2]: { 
// 			mappings: ICDAlarmIncidentRegistriesMappings 
// 		}	
// 	}
// );

// describeWithMixins('AlarmServiceTest', [ elasticsearchTestMixin ], () => {
// 	chai.should();
// 	chai.use(chaiAsPromised);
// 	const container = new inversify.Container();
// 	container.bind(AlarmService).to(AlarmService);
// 	container.bind(ICDAlarmIncidentRegistriesIndex).to(ICDAlarmIncidentRegistriesIndex);
// 	container.bind(elasticsearch.Client).toConstantValue(elasticsearchTestMixin.elasticsearchClient);

// 	const elasticsearchClient = container.get(elasticsearch.Client);
// 	const service = container.get(AlarmService);


// 	beforeEach(function (done) {
// 		const geoLocation = randomDataGenerator.generate(TICDAlarmIncidentRegistryDoc.meta.props.geo_location);
// 		const sharedData = {
// 			icd_data: {
// 				device_id: randomDataGenerator.generate('DeviceId'),
// 				id: randomDataGenerator.generate('UUIDv4'),
// 				location_id: geoLocation.location_id
// 			},
// 			geo_location: geoLocation,
// 			account: {
// 				account_id: randomDataGenerator.generate('UUIDv4'),
// 				group_id: randomDataGenerator.generate('UUIDv4')
// 			}
// 		};
// 		this.currentTest.icdAlarmIncidentRegistries1 = generateData(month1, sharedData);
// 		this.currentTest.icdAlarmIncidentRegistries2 = generateData(month2, sharedData);
		
// 		Promise.all([
// 			elasticsearchTestMixin.populateDoctypeWithData(index1, 'icdalarmincidentregistry', this.currentTest.icdAlarmIncidentRegistries1),
// 			elasticsearchTestMixin.populateDoctypeWithData(index2, 'icdalarmincidentregistry', this.currentTest.icdAlarmIncidentRegistries2)
// 		])
// 			.then(result => done())
// 			.catch(done);
// 	});

// 	afterEach(function (done) {
// 		Promise.all([
// 			elasticsearchTestMixin.clearDoctype(index1, 'icdalarmincidentregistry', this.currentTest.icdAlarmIncidentRegistries1),
// 			elasticsearchTestMixin.clearDoctype(index2, 'icdalarmincidentregistry', this.currentTest.icdAlarmIncidentRegistries2)
// 		])
// 			.then(() => done())
// 			.catch(done);
// 	});

// 	describe('#retrieveByICDId', () => {
// 		it('should retrieve all alarms by ICD id', function (done) {
// 			const icdId = this.test.icdAlarmIncidentRegistries1[0].icd_data.id;

// 			service.retrieveByICDId(icdId, month2, moment(month1).endOf('month'), { size: 20 })
// 				.then(({ items }) => items)
// 				.should.eventually.deep.equal(
// 					this.test.icdAlarmIncidentRegistries1.reverse()
// 						.concat(this.test.icdAlarmIncidentRegistries2.reverse())
// 				)
// 				.notify(done);
// 		});
// 	});

// 	describe('#retrieveByIncidentId', () => {
// 		it('should retrieve alarm by incident id', function (done) {
// 			const incidentId = this.test.icdAlarmIncidentRegistries1[0].id;

// 			service.retrieveByIncidentId(incidentId, month2, moment(month1).endOf('month'))
// 				.then(({ items }) => items[0])
// 				.should.eventually.deep.equal(this.test.icdAlarmIncidentRegistries1[0])
// 				.notify(done);
// 		});
// 	});
// });

// function generateData(date, sharedData) {

// 	return Array(10).fill(null)
// 		.map((emptyData, i) => {
// 			const time = moment(date).add(i, 'days').toISOString();

// 			return _.merge(
// 				randomDataGenerator.generate(TICDAlarmIncidentRegistryDoc),
// 				{ 
// 					incident_time: time,
// 					created_at: time
// 				},
// 				sharedData
// 			);
// 		});
// }