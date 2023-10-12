import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TPlumbingFailure = t.enums({
  0: 'Not Sure',
  1: 'Other',
  2: 'Cracked / Burst Pipe',
  3: 'Bad Connector / Supply Line',
  4: 'Sprinkler Head',
  5: 'Running Toilet',
  6: 'Pinhole Leak',
  7: 'Reverse Osmosis',
  8: 'Relief Valve Discharging'
});

export default wrapEnum(TPlumbingFailure, true);