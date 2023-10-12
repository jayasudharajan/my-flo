import t from 'tcomb-validation';

const TProfileParams = t.struct({
  home: t.Number,
  away: t.Number,
  vacation: t.maybe(t.Number)
});

export default TProfileParams;