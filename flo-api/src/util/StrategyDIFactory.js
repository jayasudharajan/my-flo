import Strategy from 'passport-strategy';

export default class StrategyDIFactory extends Strategy {
  constructor(appContainer, getStrategy) {
    super();
    this.appContainer = appContainer;
    this.getStrategy = getStrategy;
  }


  authenticate(req, ...args) {
    const strategy = this.getStrategy(req.container || this.appContainer);
    const authenticate = strategy.authenticate;
    const context = Object.assign(strategy, this);

    return authenticate.call(context, req, ...args);
  }
}