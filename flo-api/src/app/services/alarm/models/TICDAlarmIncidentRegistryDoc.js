import { createTypeFromMapping } from '../../utils/elasticsearchUtils';
import mappings from './mappings/icdalarmincidentregistries.js';

export default createTypeFromMapping(mappings.icdalarmincidentregistry);