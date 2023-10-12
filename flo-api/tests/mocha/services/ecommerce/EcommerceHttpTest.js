// const chai = require('chai');
// const config = require('../../../../dist/config/config');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const AppServerTestMixin = require('../../utils/AppServerTestMixin');
// const AppServerFactory = require('../../../../dist/AppServerFactory');
// const ContainerFactory = require('./resources/ContainerFactory');
// const AppServerTestUtils = require('../../utils/AppServerTestUtils');

// const container = ContainerFactory();
// const appServerFactory = new AppServerFactory(AppServerTestUtils.withRandomPort(config), container);
// const appServerTestMixin = new AppServerTestMixin(appServerFactory);

// describeWithMixins('EcommerceHttpTest', [ appServerTestMixin ], () => {
//   const endpoint = '/api/v1/ecommerce/order-payment-completed';

//   describe('POST ' + endpoint, function() {
//     it('should send successfully an email for order payment completed', function (done) {
//       const data = {
//         customer: {
//           email: 'hi@hi.com'
//         }
//       };

//       chai.request(appServerFactory.instance())
//         .post(endpoint)
//         .send(data)
//         .should.eventually.deep.include({ status: 200, body: data}).notify(done);
//     });
//   });
// });


