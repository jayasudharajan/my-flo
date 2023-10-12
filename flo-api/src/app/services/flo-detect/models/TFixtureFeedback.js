import t from 'tcomb-validation';

const TFixtureFeedback = t.struct({
  accurate: t.Boolean,
  reason: t.maybe(t.Number),
  other_reason: t.maybe(t.String)
});

export default TFixtureFeedback;