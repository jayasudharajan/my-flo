'use strict'

require('@instana/collector')();
import express from 'express';
import { normalizeError } from './util/errorUtils';

class AppServerFactory {
  constructor(config, container, options) {
    this.config = config;
    this.options = options;
    this.container = container;
    this.app = null;
  }

  log(message) {
    if(this.options && this.options.verbose) {
      console.log(message);
    }
  }

  startApp() {
    // Create multiple node workers.
    if(this.config.cluster) {
      if (cluster.isMaster) {
        // Create a worker for each CPU.
        for (var i = 0; i < this.config.numberOfWorkers; i += 1) {
          cluster.fork();
        }
      } else {
        this.app = this.createWorker(this.config, this.container);
      }

      cluster.on('exit', worker => {
        // this.log('Worker %d died :(', worker.id);
        cluster.fork();
      });
    } else {
      if (this.config.env == "development") {
        this.log('Single CPU app started.');
      }
      this.app = this.createWorker(this.config, this.container);
    }

    return this.app;
  }

  createWorker(config, container) {
    const app = express();

    // Show environment.
    if(config.env == "development") {
      this.log("ENV: " + config.env);
    }

    // Inject express app to express config.
    require('./config/express')(app, container, this.options);

    app.use((err, req, res, next) => {
      if (req.log) {
        req.log.error({ err: err });
      }

      const { status, message, ...data } = normalizeError(err);

      res.status(status).json({ error: true, message, ...data });
    });

    // Start servers.
    var server = app.listen(config.port, () => {
      var host = server.address().address;
      if(config.env == "development") {
        this.log('Flo app listening at http://%s:%s', host, config.port);
      }
    });

    return server;
  }

  instance() {
    return this.app || this.startApp();
  }
}

export default AppServerFactory;
