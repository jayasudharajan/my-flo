/**

Objective:  need a way to capture a variety of formats of exceptions, including SQL errs, 
and stringify to JSON in a consistent way.

console.log(err)
console.log(err.message)
console.log(err.stack)
console.log(err.code)
console.log(err.syscall)
console.log(err.name)
console.log(err.toString())

**/

// Potential ES6 Approach
class ExtendableError extends Error {
  constructor(message = '') {
    super(message);

    Object.defineProperty(this, 'message', {
      enumerable : false,
      value : message
    });

    Object.defineProperty(this, 'name', {
      enumerable : false,
      value : this.constructor.name,
    });

    if (Error.hasOwnProperty('captureStackTrace')) {
      Error.captureStackTrace(this, this.constructor);
      return;
    }

    Object.defineProperty(this, 'stack', {
      enumerable : false,
      value : (new Error(message)).stack,
    });
  }
}

class FloError extends ExtendableError {
	constructor(message = 'Error message.') {
		super(message);
	}
}

export default FloError;
