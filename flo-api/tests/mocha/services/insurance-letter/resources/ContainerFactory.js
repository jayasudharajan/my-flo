const inversify = require('inversify');
const LocationContainerFactory = require('../../location-v1_5/resources/ContainerFactory');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const InsuranceLetterService = require('../../../../../dist/app/services/insurance-letter/InsuranceLetterService');
const InsuranceLetterRequestLogTable = require('../../../../../dist/app/services/insurance-letter/InsuranceLetterRequestLogTable');
const InsuranceLetterPDFCreator = require('../../../../../dist/app/services/insurance-letter/InsuranceLetterPDFCreator');
const containerUtil = require('../../../../../dist/util/containerUtil');
const AWS = require('aws-sdk');

class InsuranceLetterPDFCreatorMock {
  constructor() {
    this.pdfGenerationRequests = [];
  }

  createInsuranceLetterPDF(user) {
    this.pdfGenerationRequests.push(user);

    return Promise.resolve({});
  }

  getPDFGenerationRequests() {
    return this.pdfGenerationRequests;
  }

  clean() {
    this.pdfGenerationRequests = [];
  }
}

class S3Mock {
  constructor() {}

  getSignedUrl(method, config, callback) {
    callback(null, `${config.Bucket}/${config.Key}`);
  }
}

function ContainerFactory() {
  const container = new inversify.Container();

  container.bind(InsuranceLetterRequestLogTable).to(InsuranceLetterRequestLogTable);
  container.bind(InsuranceLetterService).to(InsuranceLetterService);
  container.bind(InsuranceLetterPDFCreator).toConstantValue(new InsuranceLetterPDFCreatorMock());
  container.bind(AWS.S3).toConstantValue(new S3Mock());

  return [
    LocationContainerFactory(),
    UserAccountContainerFactory()
  ].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;