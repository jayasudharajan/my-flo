const chai = require('chai');
const t = require('tcomb-validation');
const uuid = require('node-uuid');
const customTypes = require('../../../../dist/app/models/definitions/CustomTypes');

describe('CustomTypes', function() {

  const validate = t.validate;
  const expect = chai.expect;
  
  describe('bcrypt hash validator', function () {
    it('should return true when string is a bcrypt hash', function () {
      expect(
        validate("$2b$10$Ld1iyjXFGt52.yf9lMbyUOvZ/.twWdkMeQUq.7ekxkaEqB.O8FGVa", customTypes.HashPassword).isValid()
      ).to.equal(true);
    });

    it('should return false when string is empty', function () {
      expect(
        validate("", customTypes.HashPassword).isValid()
      ).to.equal(false);
    });

    it('should return false when string is a regular password looking value', function () {
      expect(
        validate('.jR^]Bcqu8Q5YP', customTypes.HashPassword).isValid()
      ).to.equal(false);
    });

  });

  describe('UUIDv4 validator', function () {
    it('should return true when string is a valid uuid v4', function () {
      expect(
        validate(uuid.v4(), customTypes.UUIDv4).isValid()
      ).to.equal(true);
    });

    it('should return false when string is not an uuid', function () {
      expect(
        validate('dasdasdas', customTypes.UUIDv4).isValid()
      ).to.equal(false);
    });

    it('should return false when string is not a uuid but not v4', function () {
      expect(
        validate(uuid.v1(), customTypes.UUIDv4).isValid()
      ).to.equal(false);
    });
  });

  describe('ISO8601Date validator', function () {
    it('should return true when string is a valid ISO8601 date', function () {
      expect(
        validate(new Date().toISOString(), customTypes.ISO8601Date).isValid()
      ).to.equal(true);
    });

    it('should return false when string is not a date', function () {
      expect(
        validate('dasdasdas', customTypes.ISO8601Date).isValid()
      ).to.equal(false);
    });

    it('should return false when string is a date but not in ISO8601 format', function () {
      expect(
        validate(new Date().toString(), customTypes.ISO8601Date).isValid()
      ).to.equal(false);
    });
  });


  describe('DeviceId validator', function () {
    it('should return true when string is a valid device id', function () {
      expect(
        validate('8CC7AA027850', customTypes.DeviceId).isValid()
      ).to.equal(true);
    });

    it('should return false when string is not a valid device id', function () {
      expect(
        validate('dasdasdas', customTypes.DeviceId).isValid()
      ).to.equal(false);
    });
  });
});