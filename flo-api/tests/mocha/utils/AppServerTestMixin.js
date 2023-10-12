const chai = require('chai');
const chaiHttp = require('chai-http');

class AppServerTestMixin {

  constructor(appServerFactory) {
    this.appServerFactory = appServerFactory;
    chai.use(chaiHttp);
  }

  afterEach(done) {
    this.appServerFactory.instance().close(done);
  }

  beforeEach() {
    this.currentTest.app = this.appServerFactory.instance();
  }
}

module.exports = AppServerTestMixin;