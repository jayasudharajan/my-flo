import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import DirectiveMQTTMessage from './TDirectiveMQTTMessage';

const TDirectiveKafkaMessage = t.struct({
	icd_id: tcustom.UUIDv4,
	state: t.Integer,
	directive: DirectiveMQTTMessage
}, {
	defaultProps: {
		state: 1
	}
});

TDirectiveKafkaMessage.create = data => TDirectiveKafkaMessage(data);

export default TDirectiveKafkaMessage;