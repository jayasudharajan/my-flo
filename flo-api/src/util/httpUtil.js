import _ from 'lodash';

// Prevent undesired JSON attributes in the Request.
// Adds to existing validationErrors.
// TODO: could this be done as middleware?
export function allow(allowedFields, params, validationErrors) {

  for (let param of Object.keys(params)) {
    
    if(_.indexOf(allowedFields, param) < 0) {
      if(!validationErrors) {
        validationErrors = [];
      }
      validationErrors.push(
      { "param": param,
        "msg": "'" + param + "' is an invalid attribute." });
    }
  }

  return validationErrors;
}

/**
 * Strip sensitive fields from returned user JSON.
 */
export function filterUser(user) {
  if(user) {
    delete user["password"];
    delete user["reset_password_token"];
    delete user["reset_password_expires"];
  }
  return user;
}

/**
 * Format response error with status.
 */
export function responseError(res, err) {
  if(!err.statusCode) err.statusCode = 500;
  next({ status: err.statusCode, message: err.message  });
}

// Validate request against specific validation schema.
export function validate(req, schema, addFields, removeFields={}) {
  // TODO: add removeFields options.
  let newSchema = {};
  if(addFields) {
    for(let field of addFields) {
      newSchema[field] = schema[field];
    }
  } else {
    newSchema = schema;
  }
  req.validate(newSchema);
  return req.validationErrors();
}

// Remove duplicate field errors.
export function formatErrors(errs) {
  return _.uniqBy(errs, 'param');
}

// Format AXIOS http errors for middleware.
export function formatError(err) {
  if(err.response) {
    err.status = err.response.status;
    err.message = err.response.data;
  }
  return err;
}

export function isMobileUserAgent(req) {
  return [/Flo\-iOS/, /Flo\-Android/].some(pattern => req.headers['user-agent'].match(pattern));
}