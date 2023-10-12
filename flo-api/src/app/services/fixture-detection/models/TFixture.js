import t from 'tcomb-validation';
import TFixtureFeedback from './TFixtureFeedback';
const TFixture = t.struct({
  index: t.Number,
  gallons: t.Number,
  name: t.String,
  ratio: t.Number,
  type: t.Number,
  feedback: t.maybe(TFixtureFeedback)
});

export default TFixture;