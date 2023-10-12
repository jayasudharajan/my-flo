import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TAlertCause = t.enums({
  0: 'Not Sure',
  1: 'Other',
  2: 'Irrgiation',
  3: 'Pool / Hot Tub',
  4: 'Hose Bibb',
  5: 'Plumbing Failure',
  6: 'Toilet Flapper',
  7: 'Long Shower',
  8: 'Multiple Fixtures On at Once',
  9: 'Water Softener / Filtration',
  10: 'Drip Irrigation',
  11: 'Fixture Left On'
});



export default wrapEnum(TAlertCause, true);