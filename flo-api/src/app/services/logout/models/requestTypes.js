import t from 'tcomb-validation';

export default {
  logout: {
    body: t.struct({
      mobile_device_id: t.maybe(t.String)
    })
  }
};  