import { ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import AlertFeedbackTable from './AlertFeedbackTable';
import AlertFeedbackFlowTable from './AlertFeedbackFlowTable';
import AlertFeedbackService from './AlertFeedbackService';
import AlertFeedbackController from './AlertFeedbackController';
import AlertFeedbackRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind(AlertFeedbackTable).to(AlertFeedbackTable);
  bind(AlertFeedbackFlowTable).to(AlertFeedbackFlowTable);
  bind(AlertFeedbackService).to(AlertFeedbackService);
  bind(AlertFeedbackController).to(AlertFeedbackController);
  bind(AlertFeedbackRouter).to(AlertFeedbackRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/alertfeedback', container => container.get(AlertFeedbackRouter).router));
});