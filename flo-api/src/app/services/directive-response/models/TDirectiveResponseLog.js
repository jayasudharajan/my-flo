import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TDirectiveResponse from './TDirectiveResponse';

const TDirectiveResponseLog = TDirectiveResponse.extend({
  icd_id: tcustom.UUIDv4,
  created_at: tcustom.ISO8601Date
});

export default TDirectiveResponseLog;