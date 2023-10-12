import t from 'tcomb-validation';

const TTriggerResponseMetadata = t.struct({
	id: t.String,
	timestamp: t.Number
});

TTriggerResponseMetadata.create = data => TTriggerResponseMetadata(data);

export default TTriggerResponseMetadata;