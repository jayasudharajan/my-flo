import t from 'tcomb-validation';
import TTriggerResponseMetadata from './TTriggerResponseMetadata';

const TAlertDetectedTriggerResponse = t.struct({
	data: t.list(
		t.struct({
			alert_id: t.String,
			alert_name: t.String,
			system_mode: t.String,
			full_address: t.String,
			created_at: t.String,
			meta: TTriggerResponseMetadata
		})
	)
});

TAlertDetectedTriggerResponse.create = data => TAlertDetectedTriggerResponse(data);

export default TAlertDetectedTriggerResponse;