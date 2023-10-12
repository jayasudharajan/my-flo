const inversify = require('inversify');
const serviceContainerModule = require('../../../../../dist/app/services/google-smart-home/container').containerModule;
const DirectivesContainerFactory = require('../../directives/resources/ContainerFactory');
const DeviceSystemModeContainerFactory = require('../../device-system-mode/resources/ContainerFactory');
const Influx = require('influx');
const InfoService = require('../../../../../dist/app/services/info/InfoService');
const AlertsService = require('../../../../../dist/app/services/alerts/AlertsService');
const LogoutService = require('../../../../../dist/app/services/logout/LogoutService');
const DeviceStateService = require('../../../../../dist/app/services/device-state/DeviceStateService');
const moment = require('moment');


function ContainerFactory() {
  const mockInfluxDb = {
    _shouldHaveResult: true,
    _toggle() {
      this._shouldHaveResult = !this._shouldHaveResult;
    },
    query() {

      return !this._shouldHaveResult ?
        Promise.resolve([]) :
        Promise.resolve([{
          time: new Date(),
          f: 9.00,
          p: 10.00,
          sm: 2,
          t: 99,
          v: 1,
          wf: 5.00,
          did: 'abc0110x3',
          online: true,
          on: true,
          currentModeSettings: {
            mode: 2
          }
        }]);
    }
  };
  const container = new inversify.Container();

  container.bind(LogoutService).toConstantValue(new (class LogoutServiceStub {
    logout() {
      return Promise.resolve();
    }
  }));

  container.bind(DeviceStateService).toConstantValue(new (class DeviceStateServiceStub {
    setInitialState() {
      return Promise.resolve();
    }

    deleteDeviceState() {
      return Promise.resolve();
    }
  }));

  container.bind(Influx.InfluxDB).toConstantValue(mockInfluxDb);
  DirectivesContainerFactory.loadContainerModules(container);
  DeviceSystemModeContainerFactory.loadContainerModules(container);

  const infoServiceMock = {
    _devices: [],
    _addDevice(icd) {
      infoServiceMock._devices = [icd];
    },
    users: {
      retrieveByUserId() {
        return Promise.resolve({
          items: [{
            devices: infoServiceMock._devices
          }]
        });
      }
    }
  };
  container.bind(InfoService).toConstantValue(infoServiceMock);
  const alertServiceMock = {
    getFullActivityLog() {
      return Promise.resolve({
        total: 0,
        items: []
      });
    }

  };
  container.bind(AlertsService).toConstantValue(alertServiceMock);

  container.load(serviceContainerModule);

  return container;
}

module.exports = ContainerFactory;