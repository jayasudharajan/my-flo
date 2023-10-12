import AlertFeedbackTable from './AlertFeedbackTable';
import AlertFeedbackFlowTable from './AlertFeedbackFlowTable';
import DIFactory from  '../../../util/DIFactory';


class AlertFeedbackService {

  constructor(alertFeedbackTable, alertFeedbackFlowTable) {
    this.alertFeedbackTable = alertFeedbackTable;
    this.alertFeedbackFlowTable = alertFeedbackFlowTable;
  }

  retrieveFeedback(icdId, incidentId) {
    return this.alertFeedbackTable.retrieve(icdId, incidentId)
      .then(({ Item }) => Item || {});
  }

  submitFeedback(alertFeedback) {
    return this.alertFeedbackTable.create(alertFeedback);
  }

  retrieveFlow(alarmId, systemMode) {
    return this.alertFeedbackFlowTable.retrieve(alarmId, systemMode)
      .then(({ Item }) => Item || {});
  }
}

export default new DIFactory(AlertFeedbackService, [AlertFeedbackTable, AlertFeedbackFlowTable]);