import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TRegistrationFlow = wrapEnum(t.enums.of(['mobile', 'web']));

export default TRegistrationFlow;
