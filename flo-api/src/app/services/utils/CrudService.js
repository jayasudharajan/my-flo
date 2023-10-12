
export default class CrudService {
  constructor(table) {
    this.table = table;
  }

  create(data) {
    return this.table.create(data);
  }

  retrieve(...keys) {
    return this.table.retrieve(...keys)
      .then(({ Item }) => Item || {});
  }

  update(data) {
    return this.table.update(data);
  }

  patch(keys, data) {
    return this.table.patch(keys, data);
  }

  remove(...keys) {
    return this.table.remove(...keys);
  }

  archive(...keys) {
    return this.table.archive(...keys);
  }

}