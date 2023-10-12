'use strict'
import bodyParser from 'body-parser';
import glob from 'glob';
import config from './config';
import cors from 'cors';
import passport from 'passport';
import { login, passwordReset } from '../app/middleware/localStrategy.js';
import enforce from 'express-sslify';
import _ from 'lodash';
import bunyan from 'bunyan';
import uuid from 'node-uuid';
import helmet from 'helmet';
import addAppUsed from '../app/middleware/addAppUsed';
import xmlparser from 'express-xml-bodyparser';
const constants = require('./constants');
import OAuth2Service from '../app/services/oauth2/OAuth2Service';
import LegacyAuthService from '../app/services/legacy-auth/LegacyAuthService';
import Logger from '../app/services/utils/Logger';
import MultifactorAuthenticationService from '../app/services/multifactor-authentication/MultifactorAuthenticationService';
import { Container } from 'inversify';
import reflect from 'reflect-metadata';
import StrategyDIFactory from '../util/StrategyDIFactory';
import http from 'http';

export default (app, container, options) => {

  const xml2jsDefaults = {
    explicitArray: false,
    normalize: false,
    normalizeTags: false,
    trim: false
  };

  function logInfo(logger, data, message) {
    if(options && options.verbose) {
        logger.info(data, message);
    }
  }

  app.set("strict routing", true);
  app.set("case sensitive routing", true);

  // use HTTPS(true) in case you are behind a load balancer (e.g. AWS)
  if (config.enforceHttps) {
    app.use(enforce.HTTPS({ trustProtoHeader: true }));
  }

  // Remove "X-Powered-By:Express" header.
  app.set('x-powered-by', false);

  app.use(helmet({
    hsts: {
        maxAge: 31536000000, // one year in milliseconds
        includeSubdomains: true,
        force: true
    }
  }));

  // We need the rawBody to verify hmac signatures like the use use by Shopify
  app.use(function(req, res, next) {
    req.rawBody = '';

    req.on('data', function(chunk) {
      req.rawBody += chunk;
    });

    next();
  });

  // Body parsers for incoming requests.
  app.use(bodyParser.urlencoded({ extended: true }));
  app.use(bodyParser.json({ extended: true, limit: '400kb' })); // 400KB is DynamoDB limit for a single record
  app.use(xmlparser(xml2jsDefaults));

  // Strip sensitive data from response
  app.use((req, res, next) => {
    const resJson = res.json.bind(res);
    const resSend = res.send.bind(res);

    res.json = data => resJson(filterResponse(data));
    res.send = data => resSend(filterResponse(data));

    next();

    function filterResponse(data) {
        if (!_.isString(data) && _.isArrayLike(data)) {
            return _.map(data, elm => filterResponse(elm));
        } else if (_.isObject(data)) {
            return _.chain(data)
                .omit(['password', 'email_hash', 'client_secret'])
                .omitBy((val, key) => key[0] === '_')
                .mapValues(val => filterResponse(val))
                .value();
        } else {
            return data;
        }
    }
  });

  // Configure CORS.
  app.use(cors({
    credentials: true,
    origin: '*',
    methods: ['HEAD', 'GET', 'PUT', 'POST', 'PATCH', 'DELETE', 'OPTIONS']
  }));


  // Logging
  let logger = bunyan.createLogger({ name: 'flo-api-' + config.env });


  app.use((req, res, next) => {
    const id = uuid.v4();
    const now = Date.now();
    const body = _.mapValues(req.body, (value, key) => 
      ((config.confidentialFields || []).indexOf(key) < 0) ? 
        value : 
        '[REDACTED]'
    );
    const headers = _.extend({}, (req.headers || {}), { authorization: req.headers.authorization ? '[REDACTED]' : '' });
    const startOpts = {
        req: _.extend({} , req, { body }, { headers }),
        body
    };

    req.log = logger.child({
      type: 'request',
      id: id,
      serializers: logger.constructor.stdSerializers
    });

    req.log.addSerializers({
      cached_lookup: ({ result, isFromCache }) => ({ isFromCache: !!isFromCache, result: _.isString(result) ? result : JSON.stringify(result) })
    });


    req.container = new Container();
    req.container.parent = container;
    req.container.bind(Logger).toConstantValue(req.log);
    req.container.bind(http.ClientRequest).toConstantValue(req);

    res.setHeader('x-request-id', id);

    logInfo(req.log, startOpts, 'start request');

    const time = process.hrtime();
    res.on('finish', function responseSent() {
      const diff = process.hrtime(time);

      logInfo(req.log, {res: res, duration: diff[0] * 1e3 + diff[1] * 1e-6}, 'end request');
    });

    next();
  });

  app.use(addAppUsed);

  if (container.isBound(OAuth2Service)) {
    passport.use('oauth2', new StrategyDIFactory(container, container => container.get(OAuth2Service).getAuthStrategy()));
    passport.use('client-basic', new StrategyDIFactory(container, container => container.get(OAuth2Service).getClientBasicAuthStrategy()));
    passport.use('client-password', new StrategyDIFactory(container, container => container.get(OAuth2Service).getClientPasswordAuthStrategy()));
  }

  if (container.isBound(LegacyAuthService)) {
      passport.use('legacy', new StrategyDIFactory(container, container => container.get(LegacyAuthService).getAuthStrategy()));
  }

  passport.use('local-login', login);
  passport.use('local-password-reset', passwordReset);

  if (container.isBound(MultifactorAuthenticationService)) {
    passport.use('mfa', new StrategyDIFactory(container, container => container.get(MultifactorAuthenticationService).getAuthStrategy()));
  }

  app.use(passport.initialize());

  // Set default route.
  app.get('/', function(req, res) {
    res.send({
        "env": config.env,
        "date": new Date().toISOString()
    });
  });

  // Add routes.
  const routers = [
    ...glob.sync(config.root + '/app/routes/*.js').map(routerPath => require(routerPath)),
    ...(container.isBound('RouterFactory') ? container.getAll('RouterFactory') : [])
  ];

  routers.forEach(function(router) {
    router(app, container);
  });
}
