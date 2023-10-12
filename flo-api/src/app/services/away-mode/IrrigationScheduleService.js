import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';

class IrrigationScheduleService {
  constructor(lambdaClient, config) {
    this.lambdaClient = lambdaClient;
    this.config = config;
  }

  retrieveIrrigationSchedule(deviceId) {
    return this.lambdaClient.invoke({
      FunctionName: this.config.irrigationScheduleLambda,
      InvocationType: 'RequestResponse', 
      Payload: JSON.stringify({
        device_id: deviceId
      })
    })
    .promise()
    .then(({ Payload }) => JSON.parse(Payload));
  }
}

export default new DIFactory(IrrigationScheduleService, [AWS.Lambda, 'AwayModeConfig']);