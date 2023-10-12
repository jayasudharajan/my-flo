import t from 'tcomb-validation';

export default {
  retrieveVersionFeatures: {
    params: t.struct({
      version: t.String
    })
  }
};