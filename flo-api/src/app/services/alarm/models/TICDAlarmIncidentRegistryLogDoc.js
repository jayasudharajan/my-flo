import { createTypeFromMapping } from '../../utils/elasticsearchUtils';
import mappings from './mappings/icdalarmincidentregistrylogs';

export default createTypeFromMapping(mappings.icdalarmincidentregistrylog);