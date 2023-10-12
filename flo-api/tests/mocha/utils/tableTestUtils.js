const _ = require('lodash');
const ValidationException = require('../../../dist/app/models/exceptions/ValidationException');
const RandomDataGenerator = require('./RandomDataGenerator');
const clone = require('clone');

const randomDataGenerator = new RandomDataGenerator();

function crudTableTests(table, options) {
  const getRetrieveParamsValues = (options && options.getRetrieveParamsValues) || _getRetrieveParamsValues;
  const getUpdatedRecord = (options && options.getUpdatedRecord) || _getUpdatedRecord;

  describe('#create()', function() {
    it('should create successfully a record', function (done) {
      const record = generateRecord(table);
      const promise = table.create(record)
        .then(function() {
          return table.retrieve(getRetrieveParamsValues(table, record));
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        });

      if (options && options.testCreate) {
        options.testCreate(record, promise, done);
      } else {
        promise
          .should.eventually.deep.equal(record).notify(done);
      }
    });

    it('should not create a record because validation errors', function (done) {
      const record = generateAnInvalidRecord(table);

      table.create(record)
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });

  describe('#update()', function() {
    it('should update successfully a record', function (done) {
      const record = generateRecord(table);
      const updatedRecord = getUpdatedRecord(table, record);
      const promise = table.create(record)
        .then(function() {
          return table.update(updatedRecord);
        })
        .then(function() {
          return table.retrieve(getRetrieveParamsValues(table, record));
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        });

      if (options && options.testUpdate) {
        options.testUpdate(updatedRecord, promise, done);
      } else {
        promise
          .should.eventually.deep.equal(updatedRecord).notify(done);
      }
    });

    it('should not update a record because validation errors', function (done) {
      const record = generateRecord(table);
      const updatedRecord = generateAnInvalidRecord(table, record);

      table.create(record)
        .then(function() {
          return table.update(updatedRecord);
        })
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });

  describe('#patch()', function() {
    it('should patch successfully a record', function (done) {
      const record = generateRecord(table, { maybeIgnored: true });
      const updatedRecord = getUpdatedRecord(table, record, { maybeIgnored: true });
      const retrieveParamsValues = getRetrieveParamsValues(table, record);
      const promise = table.create(record)
        .then(function() {
          return table.patch(retrieveParamsValues, updatedRecord);
        })
        .then(function() {
          return table.retrieve(retrieveParamsValues);
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        });

      if (options && options.testPatch) {
        options.testPatch(updatedRecord, promise, done);
      } else {
        promise
          .should.eventually.deep.equal(updatedRecord).notify(done);
      }
    });
  });
}

function generateRecord(table, options) {
  const record = randomDataGenerator.generate(table.getType(), options || { maybeDeleted: true });

  return record;
}

function getNonKeyOrRangeProperties(table) {
  const type = table.getType();

  return _.chain(type.meta.props)
    .omit([table.rangeName, table.keyName])
    .keys()
    .value();
}

function generateAnInvalidRecord(table, record) {
  if(!record) {
    record = generateRecord(table);
  }
  const property = getNonKeyOrRangeProperties(table)[0];
  const invalidValue = randomDataGenerator.generateInvalid(table.getType().meta.props[property]);

  return Object.assign(
    {},
    record,
    { [property]: invalidValue }
  );
}

function _getUpdatedRecord(table, record, options) {
  const updatedRecord = Object.assign(
    generateRecord(table, options),
    _.pick(record, [table.keyName, table.rangeName])
  );

  return updatedRecord;
}

function _getRetrieveParamsValues(table, record) {
  return _.pick(record, [table.keyName, table.rangeName]);
}

module.exports = {
  crudTableTests: crudTableTests,
  getUpdatedRecord: _getUpdatedRecord,
  generateAnInvalidRecord: generateAnInvalidRecord,
  generateRecord: generateRecord,
  getRetrieveParamsValues: _getRetrieveParamsValues
};