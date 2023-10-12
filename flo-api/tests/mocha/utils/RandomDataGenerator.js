const _ = require('lodash');
const t = require('tcomb');
const uuid = require('uuid');
const chance = require('chance')();
const moment = require('moment');

const defaultTypeGenerators = [
  {
    type: t.String,
    generator: () => chance.string()
  },
  {
    type: t.Number,
    generator: () => chance.floating()
  },
  {
    type: t.Integer,
    generator: () => chance.integer()
  },
  {
    type: t.Boolean,
    generator: () => chance.bool()
  },
  {
    type: t.Date,
    generator: () => chance.date()
  },
  {
    type: t.Nil,
    generator: () => chance.bool() ? null : undefined
  },
  {
    type: 'UUID',
    generator: uuid.v1
  },
  {
    type: 'UUIDv1',
    generator: uuid.v1
  },
  {
    type: 'UUIDv4',
    generator: uuid.v4
  },
  {
    type: 'ISO8601Date',
    generator: () => chance.date().toISOString()
  },
  {
    type: 'DeviceId',
    generator: () => chance.mac_address().split(':').join('').toLowerCase()
  },
  {
    type: 'MACAddress',
    generator: () => chance.mac_address()
  },
  {
    type: 'URL',
    generator: () => chance.url()
  },
  {
    type: 'Integer32',
    generator: () => chance.integer({min: Math.pow(-2, 31), max: Math.pow(2, 31) - 1})
  },
  {
    type: 'Email',
    generator: () => chance.email()
  },
  {
    type: 'HashedPassword',
    generator: () => '$2b$10$Ld1iyjXFGt52.yf9lMbyUOvZ/.twWdkMeQUq.7ekxkaEqB.O8FGVa'
  },
  {
    type: 'Password',
    generator: () =>
      _.shuffle(
        chance.string({length: 1, pool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'}) +
        chance.string({length: 1, pool: 'abcdefghijklmnopqrstuvwxyz'}) +
        chance.string({length: 8}) +
        chance.integer({min: 0, max: 9})
      )
        .join('')
  },
  {
    type: 'IPAddress',
    generator: () => chance.ip()
  },
  {
    type: 'ZeroOrOne',
    generator: () => chance.bool() ? 1 : 0
  },
  {
    type: 'HourMinuteSeconds',
    generator: () =>
      moment(chance.date().toISOString()).format('HH:mm:ss')
  },
  {
    type: 'SerialNumberCharacter',
    generator: () => chance.string({length: 1, pool: 'ABCDEFGHJKLMNPQRSTUVWXYZ'})
  }
];

class RandomDataGenerator {
  constructor(typeGenerators) {
    this.typeGenerators = defaultTypeGenerators.concat(typeGenerators || []);
  }

  generateInvalid(_type) {
    const type = _type.meta.kind === 'maybe' ? _type.meta.type : _type;
    const typeGenerator = _.find(
      this.typeGenerators.filter(({type}) => type !== t.Nil && type !== 'Password'),
      typeGenerator =>
        typeGenerator.type !== type &&
        (t.isType(typeGenerator.type) ? t.getTypeName(typeGenerator.type) : typeGenerator.type) !== (t.isType(type) ? t.getTypeName(type) : type)
    );

    return typeGenerator.generator();
  }

  generateMaybe(type, options = {}) {
    if (options.maybeIgnored || chance.bool()) {
      return this.generate(type.meta.type, options);
    } else if (options.maybeNull) {
      return null;
    } else if (options.maybeUndefined || options.maybeDeleted) {
      return undefined;
    } else {
      return this.generate(t.Nil, options);
    }
  }

  // Options:
  // maybeNull | maybeUndefined | maybeDeleted
  // maybeNull => All 'maybe' kind types will be set to null
  // maybeUndefined = All 'maybe' kind types will be set to undefined
  // maybeDeleted = All 'maybe' kind types will be removed from the object
  // maybeIgnored = All 'maybe' kind types will be generated
  generate(type, options = {}) {
    const typeGenerator = _.find(
      this.typeGenerators,
      typeGenerator =>
        typeGenerator.type === type ||
        (t.isType(typeGenerator.type) ? t.getTypeName(typeGenerator.type) : typeGenerator.type) === (t.isType(type) ? t.getTypeName(type) : type)
    );

    if (typeGenerator) {
      return typeGenerator.generator();
    } else if (!t.isType(type)) {
      throw new Error('No generator defined for ' + type);
    }

    switch (type.meta.kind) {
      case 'struct':
      case 'interface':
        return _.chain(type.meta.props)
          .omitBy(prop => options.maybeDeleted && prop.meta.kind === 'maybe')
          .mapValues(prop => this.generate(prop, options))
          .value();

      case 'subtype':
        if (type.meta.isDefinedOrUndefined) {
          return this.generateMaybe(type.meta.type, options);
        }

        return this.generate(type.meta.type);

      case 'list':
        return Array(chance.natural({max: 10})).fill(null)
          .map(() => this.generate(type.meta.type, options)
          );

      case 'enums':
        const values = _.keys(type.meta.map);
        return values[chance.natural({max: values.length - 1})];

      case 'maybe':
        return this.generateMaybe(type, options);

      case 'union':
        return this.generate(type.meta.types[chance.natural({max: type.meta.types.length - 1})], options);

      case 'dict':
        return Array(chance.natural({max: 10})).fill(null)
          .map(() => ({[this.generate(type.meta.domain, options)]: this.generate(type.meta.codomain, options)}))
          .reduce((acc, pair) => Object.assign(acc, pair), {});

      default:
        throw new Error('No generator defined for ' + type);
    }
  }

  chooseUniqueEnums(type, number) {

    if (!type || !t.isType(type) || type.meta.kind !== 'enums') {
      throw new Error(type + ' is not of kind "enums"');
    }

    const values = _.values(type.meta.map);

    if (!number || values.length > number) {
      throw new Error('Cannot choose ' + number + ' unique enums');
    }

    return Array(number).fill(null)
      .reduce(acc => {
        const i = chance.natural({max: acc.values.length - 1});

        return {
          chosen: acc.chosen.concat([acc.values[i]]),
          values: acc.values.slice(0, i).concat(acc.values.slice(i + 1))
        };
      }, {values, chosen: []})
      .chosen;
  }
}

module.exports = RandomDataGenerator;

