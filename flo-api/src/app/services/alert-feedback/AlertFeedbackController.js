import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';
import AlertFeedbackService from './AlertFeedbackService';

class AlertFeedbackController {
  constructor(alertFeedbackService) {
    this.alertFeedbackService = alertFeedbackService;
  }

  retrieveFeedback({ params: { icd_id, incident_id } }) {
    return this.alertFeedbackService.retrieveFeedback(icd_id, incident_id);
  }

  submitFeedback({ body: alertFeedback }) {
    return this.alertFeedbackService.submitFeedback(alertFeedback);
  }

  retrieveFlow({ params: { alarm_id, system_mode } }) {
    return this.alertFeedbackService.retrieveFlow(parseInt(alarm_id), parseInt(system_mode));
  }
}

export default new DIFactory(new ControllerWrapper(AlertFeedbackController), [AlertFeedbackService])