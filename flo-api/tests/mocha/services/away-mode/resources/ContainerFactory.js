const inversify = require('inversify');
const awayModeContainerModule = require('../../../../../dist/app/services/away-mode/container').containerModule;
const TIrrigationSchedule = require('../../../../../dist/app/services/away-mode/models/TIrrigationSchedule');
const IrrigationScheduleService = require('../../../../../dist/app/services/away-mode/IrrigationScheduleService');
const DirectivesContainerFactory = require('../../directives/resources/ContainerFactory');
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');
const ICDContainerFactory = require('../../icd-v1_5/resources/ContainerFactory');

class MockIrrigationScheduleService {
  constructor(randomDataGenerator) {
    this.randomDataGenerator = randomDataGenerator;
  }
 
  retrieveIrrigationSchedule(deviceId) {
    const schedule = this.randomDataGenerator.generate(TIrrigationSchedule);

    return Promise.resolve(
      Object.assign(schedule, { device_id: deviceId })
    );
  }
}

function ContainerFactory(randomDataGenerator) {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container, randomDataGenerator);

  return container;
}

ContainerFactory.loadContainerModules = (container, randomDataGenerator) => {

  container.load(awayModeContainerModule);
  container.rebind(IrrigationScheduleService).toConstantValue(new MockIrrigationScheduleService(randomDataGenerator));

  DirectivesContainerFactory.loadContainerModules(container);

  if (!container.isBound(ICDService)) {
    ICDContainerFactory.loadContainerModules(container);
  }
};

module.exports = ContainerFactory;
