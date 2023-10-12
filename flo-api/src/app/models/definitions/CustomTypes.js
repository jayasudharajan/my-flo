import t from 'tcomb-validation';
import validator from 'validator';
import uuid_validate from 'uuid-validate';
import moment from 'moment';

export default  {
  UUIDv4: createType(
    t.String,
    'UUIDv4',
    s => validator.isUUID(s, 4),
    data => getPath(data) + ' should be a valid uuidv4'
  ),
  UUIDv1: createType(
    t.String,
    'UUIDv1',
    s => uuid_validate(s, 1),
    data => getPath(data) + ' should be a valid uuidv1'
  ),
  UUID: createType(
    t.String,
    'UUID',
    s => uuid_validate(s),
    data => getPath(data) + ' should be a valid uuid'
  ),
  DeviceId: createType(
    t.String,
    'DeviceId',
    s => s.length == 12,
    data =>  getPath(data) + ' should be a valid Device Id'
  ),
  MACAddress: createType(
    t.String,
    'MACAddress',
    s => validator.isMACAddress(s),
    data => getPath(data) + ' should be a valid MAC address'
  ),
  ISO8601Date: createType(
    t.String,
    'ISO8601Date',
    s => validator.isISO8601(s),
    data => getPath(data) + ' should be a valid ISO8601 date'
  ),
  URL: createType(
    t.String,
    'URL',
    s => validator.isURL(s),
    data => getPath(data) + ' should be a valid URL'
  ),
  Integer32: createType(
    t.Integer,
    'Integer32',
    n => n >= Math.pow(-2, 31) && n < Math.pow(2, 31)
  ),
  Email: createType(
    t.String,
    'Email',
    s => validator.isEmail(s),
    data => getPath(data) + ' should be a valid email address'
  ),
  Password: createType(
    t.String,
    'Password',
    s => /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/.test(s),
    data => getPath(data) + ' should be at least 8 characters with at least 1 lowercase letter, 1 uppercase letter, and 1 number.'
  ),
  HashPassword: createType(
    t.String,
    'HashedPassword',
    s => /^[$]2[abxy]?[$](?:0[4-9]|[12][0-9]|3[01])[$][./0-9a-zA-Z]{53}$/.test(s),
    data => getPath(data) + ' is not a bcrypt hash'
  ),
  IPAddress: createType(
    t.String,
    'IPAddress',
    s => validator.isIP(s),
    data => getPath(data) + ' should be a valid IP address'
  ),
  ZeroOrOne: createType(
    t.Integer,
    'ZeroOrOne',
    n => n === 1 || n === 0,
    data => getPath(data) + ' should be 0 or 1'
  ),
  Page: createType(
    t.String,
    'Page',
    s => Number.isInteger(new Number(s).valueOf()) && parseInt(s) > 0,
    data => getPath(data) + ' should be > 0'
  ),
  Order: createType(
    t.String,
    'Order',
    s => s === 'desc' || s === 'asc',
    data => getPath(data) + ' should be desc or asc'
  ),
  Size: createType(
    t.String,
    'Size',
    s => Number.isInteger(new Number(s).valueOf()) && parseInt(s) >= 0,
    data => getPath(data) + ' should be >= 0'
  ),
  HourMinuteSeconds: createType(
    t.String,
    'HourMinuteSeconds',
    s => moment(s, 'HH:mm:ss', true).isValid(),
    data => getPath(data) + ' should be a time in HH:mm:ss format'
  ),
  SerialNumberCharacter: createType(
    t.String,
    'SerialNumberCharacter',
    s => {
      const char = s.toUpperCase();

      return char.length == 1 && char >= 'A' && char <= 'Z' && char != 'I' && char != 'O';
    },
    data => getPath(data) + ' should be a character A-Z, exclusing I & O'
  ),
  ExactNumber(number) {
    return createType(
      t.Number,
      undefined,
      n => n === number,
      data => getPath(data) + 'should equal ' + number
    );
  },
  DefinedOrUndefined(type) {

    if (type.meta.kind == 'maybe' || type.meta.isDefinedOrUndefined) {
      return type;
    }

    const defOrUndefType = createType(
      t.maybe(type),
      undefined,
      v => v === undefined || t.validate(v, type).isValid(),
      data => getPath(data) + ' should be undefined or ' + type.displayName
    );

    defOrUndefType.meta.isDefinedOrUndefined = true;

    return defOrUndefType;
  }
};

//errorMessageGenerator is a lambda that receive an object that have the followings attributes:
//- actual: object/values to be validated
//- expected: ...
//- path: path to the attribute to be validated
//- context: ...
function createType(baseTCombType, typeName, lambdaValidation, errorMessageGenerator) {
  const newType = t.refinement(baseTCombType, lambdaValidation, typeName);

  newType.getValidationErrorMessage = (actual, expected, path, context) =>
    errorMessageGenerator({
      actual,
      expected,
      path,
      context
    });

  return newType;
}

function getPath(validationMetadata) {
  if (typeof validationMetadata.path === "undefined") {
    return validationMetadata.expected
  }
  return validationMetadata.path;
}