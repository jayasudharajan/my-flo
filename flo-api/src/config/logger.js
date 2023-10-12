var bunyan = require('bunyan');

module.exports = bunyan.createLogger({name: 'floapi'});

/*

vs. Winston...

var winston = require('winston');

module.exports = new (winston.Logger)({
  transports: [
    new (winston.transports.Console)({
      colorize  : 'all',
      timestamp : true
    })
  ],
  levels: {
    debug: 1,
    info: 3,
    error: 5,
    errorNotification: 6
  }
});

*/