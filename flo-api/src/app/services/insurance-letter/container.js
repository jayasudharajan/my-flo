import {ContainerModule} from 'inversify';
import InsuranceLetterService from './InsuranceLetterService';
import InsuranceLetterController from './InsuranceLetterController';
import InsuranceLetterRouter from './routes';
import InsuranceLetterRequestLogTable from './InsuranceLetterRequestLogTable';
import InsuranceLetterPDFCreator from './InsuranceLetterPDFCreator';
import config from '../../../config/config';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind('InsuranceLetterConfig').toConstantValue(config);
  bind(InsuranceLetterRequestLogTable).to(InsuranceLetterRequestLogTable);
  bind(InsuranceLetterPDFCreator).to(InsuranceLetterPDFCreator);
  bind(InsuranceLetterService).to(InsuranceLetterService);
  bind(InsuranceLetterController).to(InsuranceLetterController);
  bind(InsuranceLetterRouter).to(InsuranceLetterRouter);
  bind('RouterFactory')
    .toConstantValue(
      new RouterDIFactory('/api/v1/insurance-letter', container => container.get(InsuranceLetterRouter).router)
    );
});