import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TFixture from './TFixture';

const TFixturesForFeedbackData = t.struct({
  fixtures: t.list(TFixture)
});

export default TFixturesForFeedbackData;