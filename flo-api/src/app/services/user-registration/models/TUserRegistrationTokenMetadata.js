import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserRegistrationData from './TUserRegistrationData';

const TUserRegistrationTokenMetadata = t.struct({
	token_id: tcustom.UUIDv4,
	email: tcustom.Email,
	created_at: tcustom.ISO8601Date,
	token_expires_at: tcustom.ISO8601Date,
	registration_data_expires_at: tcustom.ISO8601Date,
	registration_data: TUserRegistrationData
});

TUserRegistrationTokenMetadata.create = data => TUserRegistrationSession(data);

export default TUserRegistrationTokenMetadata;