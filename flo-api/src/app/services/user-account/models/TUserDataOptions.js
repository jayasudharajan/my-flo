import _ from 'lodash';
import t from 'tcomb-validation';

const TUserDataOptions =  t.struct({
  // true if password/s are already hashed, false/undefined if plain text
  passwordHash: t.maybe(t.Boolean),
})

export default TUserDataOptions;
