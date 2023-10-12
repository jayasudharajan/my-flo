import { createTypeFromMapping } from '../../utils/elasticsearchUtils';
import mappings from './mappings/users';

export default createTypeFromMapping(mappings.user);