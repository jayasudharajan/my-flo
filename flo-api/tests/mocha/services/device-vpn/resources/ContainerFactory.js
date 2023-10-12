const inversify = require('inversify');
const DeviceVPNService = require('../../../../../dist/app/services/device-vpn/DeviceVPNService');
const TaskSchedulerService = require('../../../../../dist/app/services/task-scheduler/TaskSchedulerService');
const DirectiveService = require('../../../../../dist/app/services/directives/DirectiveService');
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');
const redisContainerModule = require('../../container_modules/redis');
const kafkaContainerModule = require('../../container_modules/kafka');
const deviceVPNContainerModule = require('../../../../../dist/app/services/device-vpn/container').containerModule;
const icdContainerModule = require('../../../../../dist/app/services/icd-v1_5/container').containerModule;
const directivesContainerModule = require('../../../../../dist/app/services/directives/container').containerModule;
const taskSchedulerContainerModule = require('../../../../../dist/app/services/task-scheduler/container').containerModule;

function ContainerFactory() {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container);

  return container;
}

ContainerFactory.loadContainerModules = container => {

  container.load(redisContainerModule);
  container.load(kafkaContainerModule);

  if (!container.isBound(TaskSchedulerService)) {
    container.load(taskSchedulerContainerModule);
  }

  if (!container.isBound(DirectiveService)) {
    container.load(directivesContainerModule);
  }

  if (!container.isBound(ICDService)) {
    container.load(icdContainerModule);
  }

  if (!container.isBound(DeviceVPNService)) {
    container.load(deviceVPNContainerModule);
  }
};

module.exports = ContainerFactory;