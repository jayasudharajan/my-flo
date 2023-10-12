import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TInsuranceLetterRequestLog = t.struct({
  location_id: tcustom.UUIDv4,
  created_at: tcustom.ISO8601Date,
  generated_at: t.maybe(tcustom.ISO8601Date),
  date_redeemed: t.maybe(tcustom.ISO8601Date),
  expiration_date: tcustom.ISO8601Date,
  renewal_date: tcustom.ISO8601Date,
  redeemed_by_user_id: t.maybe(tcustom.UUIDv4),
  generated_by_user_id: tcustom.UUIDv4,
  s3_bucket: t.maybe(t.String),
  s3_key: t.maybe(t.String)
});

export default TInsuranceLetterRequestLog;