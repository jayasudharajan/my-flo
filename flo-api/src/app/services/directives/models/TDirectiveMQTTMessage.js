import t from 'tcomb-validation';
import uuid from 'uuid';
import tcustom from '../../../models/definitions/CustomTypes';
import { TDirective, directiveDataMap } from './directiveData';

const TDirectiveMQTTMessage = t.refinement(
	t.struct({
		time: tcustom.ISO8601Date,
		id: tcustom.UUIDv4,
		ack_topic: t.String,
		directive: TDirective,
		device_id: tcustom.DeviceId,
		data: t.Any
	}, {
		defaultProps: {
			data: {},
			ack_topic: ''
		}
	}), 
	msg => t.validate(msg.data, directiveDataMap[msg.directive]).isValid(),
	'DirectiveMQTTMessage'
);

TDirectiveMQTTMessage.create = data => TDirectiveMQTTMessage({
	...({ 
		time: new Date().toISOString(),
		id: uuid.v4(),
		ack_topic: ''
	}),
	...data
});

export default TDirectiveMQTTMessage;