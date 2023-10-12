const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const _ = require('lodash');

function describeWithMixins(title, mixins, fn, timeout) {
  describe(title, function() {
    if(timeout) {
      this.timeout(timeout);
    } else {
      this.timeout(36000);
    }

    chai.should();
    chai.use(chaiAsPromised);

    before(function (done) {
      eventHandler('before', done, this);
    });

    after(function (done) {
      eventHandler('after', done, this);
    });

    beforeEach(function (done) {
      eventHandler('beforeEach', done, this);
    });

    afterEach(function (done) {
      eventHandler('afterEach', done, this);
    });

    fn.bind(this)();
  });

  function shouldHandleDone(mixin, hookName) {
    return isHookDefined(mixin, hookName) && mixin[hookName].length > 0;
  }

  function isHookDefined(mixin, hookName) {
    return typeof mixin[hookName] === "function";
  }

  function eventHandler(hookName, done, thisCtx) {
    const numberOfDonesToWait = _.reduce(mixins, function(sum, mixin) {
      return shouldHandleDone(mixin, hookName) ? sum + 1 : sum;
    }, 0);
    const donesHandler = new DonesHandler(numberOfDonesToWait);

    _.forEach(mixins, function(mixin) {
      if (isHookDefined(mixin, hookName)) {
        mixin[hookName].call(Object.assign(mixin, thisCtx || {}), donesHandler.registerDoneResult.bind(donesHandler));
      }
    });

    donesHandler
      .getResultPromise()
      .then(() => done())
      .catch(done);
  }
}

class DonesHandler {
  constructor(waitNDones) {
    this.waitNDones = waitNDones;
    this.doneResults = [];
    this.deferred = Promise.defer();

    if(waitNDones == 0) {
      this.deferred.resolve();
    }
  }

  registerDoneResult(result) {
    this.doneResults.push(result);

    if(this.doneResults.length >= this.waitNDones) {
      this.completeWithResult();
    }
  }

  completeWithResult() {
    const errors = _.filter(this.doneResults, function (done) {
      return !done;
    });

    if (errors.length == 0) {
      this.deferred.resolve();
    } else {
      this.deferred.reject(errors[0]);
    }
  }

  getResultPromise() {
    return this.deferred.promise;
  }
}

module.exports = describeWithMixins;