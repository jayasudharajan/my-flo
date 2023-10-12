
export default function TimestampMixin(baseClass) {
  return class extends baseClass {
    marshal(data) {
      const now = new Date().toISOString();

      return super.marshal({
        ...data,
        created_at: now,
        updated_at: now
      });
    }

    marshalPatch(keys, data) {
      return super.marshalPatch(keys, {
        ...data,
        updated_at: new Date().toISOString()
      });
    }
  }
}