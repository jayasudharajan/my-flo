import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import moment from 'moment';

const TAuthToken = t.struct({
    user: t.struct({
      user_id: tcustom.UUIDv4,
      email: t.String,
    }),
    timestamp: t.Integer
});

TAuthToken.create = ({ timestamp = moment().unix(), ...props }) => TAuthToken({ timestamp, ...props });

export default TAuthToken;