import ExtensibleError from './ExtensibleError';

class ValidationException extends ExtensibleError {
  constructor(errors) {
    let errorsMessages = errors.map(x => x.message);
    super("There were errors during validation. Details: " + errorsMessages.join(" ,"))
    this.status = 400;
  }
}

export default ValidationException;