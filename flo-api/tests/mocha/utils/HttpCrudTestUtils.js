const chai = require('chai');
const tableTestUtils = require('../utils/tableTestUtils');

class HttpCrudTestUtils {
  constructor(app, table, baseEndpoint) {
    this.table = table;
    this.app = app;
    this.baseEndpoint = baseEndpoint;
  }

  getUrlTemplateWithParams(isArchive) {
    var paramsUrlPart = '/:' + this.table.keyName;

    if(this.table.rangeName) {
      paramsUrlPart += '/:' + this.table.rangeName;
    }

    if(isArchive) {
      return this.baseEndpoint + '/archive' + paramsUrlPart;
    }

    return this.baseEndpoint + paramsUrlPart;
  }

  getUrlWithParams(record, isArchive) {
    return this
      .getUrlTemplateWithParams(isArchive)
      .replace(':' + this.table.keyName, record[this.table.keyName])
      .replace(':' + this.table.rangeName, record[this.table.rangeName]);
  }

  create() {
    const self = this;
    const baseEndpoint = this.baseEndpoint;

    describe('POST ' + baseEndpoint, function() {
      it('should create successfully a record', function (done) {
        const record = tableTestUtils.generateRecord(self.table);

        chai.request(self.app)
          .post(baseEndpoint)
          .send(record)
          .then(response => {
            response.should.deep.include({ status: 200, body: record});

            return self.table
              .retrieve(tableTestUtils.getRetrieveParamsValues(self.table, record))
              .then(result => result.Item);

          }).should.eventually.deep.equal(record).notify(done);
      });

      it('should not create a record due to validation errors', function (done) {
        const record = tableTestUtils.generateAnInvalidRecord(self.table);

        chai.request(self.app)
          .post(baseEndpoint)
          .send(record)
          .end((error, response, body) => {
            response.should.deep.include({ status: 400 });
            response.body.should.deep.include({ error: true });

            done();
          });
      });
    });

    return this;
  }

  update() {
    const self = this;

    describe('POST ' + self.getUrlTemplateWithParams(), function() {
      it('should update successfully a record', function (done) {
        const record = tableTestUtils.generateRecord(self.table);
        const updatedRecord = tableTestUtils.getUpdatedRecord(self.table, record);

        self.table.create(record)
          .then(() => {
            const response = chai.request(self.app)
              .post(self.getUrlWithParams(record))
              .send(updatedRecord);

            // Why body comes empty and create with some object
            response.should.eventually.deep.include({ status: 200, body: { } });

            return response;
          })
          .then(() => self.table.retrieve(tableTestUtils.getRetrieveParamsValues(self.table, record)))
          .then(returnedRecord => returnedRecord.Item)
          .should.eventually.deep.equal(updatedRecord).notify(done);
      });

      it('should not update a record because validation errors', function (done) {
        const record = tableTestUtils.generateRecord(self.table);
        const updatedRecord = tableTestUtils.generateAnInvalidRecord(self.table, record);

        self.table.create(record)
          .then(() => {
            chai.request(self.app)
              .post(self.getUrlWithParams(record))
              .send(updatedRecord)
              .end((error, response, body) => {
                response.should.deep.include({ status: 400 });
                response.body.should.deep.include({ error: true });

                done();
              });
          });
      });
    });

    return this;
  }

  patch() {
    const self = this;

    describe('PUT ' + self.getUrlTemplateWithParams(), function() {
      it('should patch successfully a record', function (done) {
        const record = tableTestUtils.generateRecord(self.table);
        const updatedRecord = tableTestUtils.getUpdatedRecord(self.table, record);
        const retrieveParamsValues = tableTestUtils.getRetrieveParamsValues(self.table, record);

        self.table.create(record)
          .then(() => {
            return chai.request(self.app)
              .put(self.getUrlWithParams(record))
              .send(updatedRecord);
          })
          .then(() => self.table.retrieve(retrieveParamsValues))
          .then(returnedRecord => returnedRecord.Item)
          .should.eventually.deep.equal(updatedRecord).notify(done);
      });
    });

    return this;
  }

  retrieve() {
    const self = this;

    describe('GET ' + self.getUrlTemplateWithParams(), function() {
      it('should return one record by device id', function (done) {
        const record = tableTestUtils.generateRecord(self.table);

        self.table.create(record)
          .then(() => {
            chai.request(self.app)
              .get(self.getUrlWithParams(record))
              .should.eventually.deep.include({ status: 200, body: record}).notify(done);
          });
      });
    });

    return this;
  }

  delete() {
    const self = this;

    describe('DELETE ' + self.getUrlTemplateWithParams(), function() {
      it('should delete successfully a record', function (done) {
        const record = tableTestUtils.generateRecord(self.table);
        const retrieveParamsValues = tableTestUtils.getRetrieveParamsValues(self.table, record);

        self.table.create(record)
          .then(() => chai.request(self.app).delete(self.getUrlWithParams(record)))
          .then(response => {
            response.should.deep.include({ status: 200 });

            return self.table.retrieve(retrieveParamsValues)
          })
          .should.eventually.deep.equal({}).notify(done);
      });
    });

    return this;
  }

  archive() {
    const self = this;

    describe('DELETE ' + self.getUrlTemplateWithParams(true), function() {
      it('should archive successfully a record', function (done) {
        const record = tableTestUtils.generateRecord(self.table);
        const retrieveParamsValues = tableTestUtils.getRetrieveParamsValues(self.table, record);
        const archivedRecord = record;
        archivedRecord.is_deleted = true;

        self.table.create(record)
          .then(() => chai.request(self.app).delete(self.getUrlWithParams(record, true)))
          .then(response => {
            response.should.deep.include({ status: 200 });

            return self.table.retrieve(retrieveParamsValues)
          })
          .should.eventually.deep.equal({ Item: archivedRecord }).notify(done);
      });
    });

    return this;
  }

  all() {
    this
      .create()
      .retrieve()
      .update()
      .patch()
      .delete()
      .archive();
  }
}

module.exports = HttpCrudTestUtils;