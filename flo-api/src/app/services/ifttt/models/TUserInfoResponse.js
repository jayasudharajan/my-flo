import t from 'tcomb-validation';

const TUserInfoResponse = t.struct({
	data: t.struct({
		id: t.String,
		name: t.String,
		url: t.maybe(t.String)
	})
});

TUserInfoResponse.create = data => TUserInfoResponse(data);

export default TUserInfoResponse;