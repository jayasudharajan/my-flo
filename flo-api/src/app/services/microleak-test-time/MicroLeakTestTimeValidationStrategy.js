import ValidationStrategy from '../utils/ValidationStrategy';

export default class MicroLeakTestTimeValidationStrategy extends ValidationStrategy {
  constructor(validationMiddleware, requestTypes, controller) {
    super(validationMiddleware, requestTypes, controller);

    this.retrievePendingTimesConfig = (req, res, next) => next();
  }
}