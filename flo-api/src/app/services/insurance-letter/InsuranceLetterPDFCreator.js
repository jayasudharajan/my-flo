import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';

class InsuranceLetterPDFCreator {

  constructor(config, lambdaClient) {
    this.config = config;
    this.lambdaClient = lambdaClient;
  }

  createInsuranceLetterPDF(user) {
    return this.lambdaClient.invoke({
      FunctionName: this.config.insuranceLetterGenerationLambda,
      InvocationType: 'Event',
      Payload: JSON.stringify(user)
    }).promise();
  }
}

export default new DIFactory(
  InsuranceLetterPDFCreator,
  ['InsuranceLetterConfig', AWS.Lambda]
);