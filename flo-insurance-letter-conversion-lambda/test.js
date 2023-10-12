const {handler} = require('./src');

const event = require('./user.json');

handler(event, {testPlease: true}, (err, result) => {
    console.log('err', err);
    console.log('result', result);
});
