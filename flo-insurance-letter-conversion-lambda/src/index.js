const conversionService = require('./Conversion');

exports.handler = (event, context, callback) => {
  new conversionService().generateLetter(event, context.testPlease)
    .then(result => callback(null, result))
    .catch(err => callback(err));
};
