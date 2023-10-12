import { createTypeFromMapping } from '../../utils/elasticsearchUtils';
import mappings from './mappings/icds';

export default createTypeFromMapping(mappings.icd);