import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TUltimaVersion = t.struct({
  model: t.String,
  version: t.String,
  checksum: t.String,
  checksum_alg: t.String,
  release_date: tcustom.ISO8601Date,
  ultima_version: t.String,
  url: t.String
});

export default TUltimaVersion;
