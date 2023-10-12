import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TEvent = t.struct({
  duration: t.Number,
  fixture: t.String,
  type: t.Integer,
  start: tcustom.ISO8601Date,
  end: tcustom.ISO8601Date,
  flow: t.Number,
  gpm: t.Number,
  cluster_means: t.maybe(t.list(t.Number)),
  label: t.maybe(t.list(t.Integer)),
  not_label: t.maybe(t.list(t.Integer)),
  sub_label: t.maybe(t.struct({
    all: t.list(t.Integer),
    individual: t.Integer
  })),
  not_sub_label: t.maybe(t.struct({
    all: t.list(t.Integer),
    individual: t.Integer
  }))
});

export default TEvent;