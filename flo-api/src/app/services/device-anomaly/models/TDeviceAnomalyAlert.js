import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TDeviceAnomalyAlert = t.struct({
  id: t.String,
  message: t.String,
  details: t.String,
  time: tcustom.ISO8601Date,
  duration: t.Integer,
  level: t.String,
  data: t.struct({
    series: t.list(t.struct({
      name: t.String,
      tags: t.dict(t.String, t.union([t.String, t.Number, t.Boolean])),
      columns: t.list(t.String),
      values: t.maybe(t.list(t.list(t.union([t.String, t.Number, t.Boolean]))))
    }))
  }),
  previousLevel: t.String
});

export default TDeviceAnomalyAlert;