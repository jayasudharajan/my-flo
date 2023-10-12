import UltimaVersionTable from './UltimaVersionTable';
import DIFactory from  '../../../util/DIFactory';

class UltimaVersionService {

  constructor(ultimaVersionTable) {
    this.ultimaVersionTable = ultimaVersionTable;
  }

  /**
   * Simple Table scan to retrieve multiple records.
   */
  scan() {
    return this.ultimaVersionTable
      .scanAll();
  }

  /**
   * Query set ultimaVersion with same hashkey.
   */
  retrieveByModel(model) {
    return this.ultimaVersionTable
      .queryPartition({ model })
      .then(result => result.Items);
  }
}

export default new DIFactory(UltimaVersionService, [UltimaVersionTable]);