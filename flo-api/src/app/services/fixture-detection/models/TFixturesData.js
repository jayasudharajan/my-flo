import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TFixture from './TFixture';

const TFixturesData = t.struct({
  request_id: tcustom.UUID,
  start_date: tcustom.ISO8601Date,
  end_date: tcustom.ISO8601Date,
  fixtures: t.list(TFixture)
});

export default TFixturesData;
