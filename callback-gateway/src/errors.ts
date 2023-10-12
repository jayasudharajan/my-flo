export class InternalError extends Error {
  constructor(
    message?: string, 
    public statusCode: number = 400, 
    public data: Record<string, any> = {}
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    this.statusCode = statusCode;
    this.data = data;
  }
}

export class ValidationError extends InternalError {
  constructor(message: string = 'Invalid payload.', data?: Record<string, any>) {
    super(message, 400, data);
  }
}

export class ForbiddenError extends InternalError {
  constructor(message: string = 'Forbidden.', data?: Record<string, any>) {
    super(message, 403, data);
  }
}

export class NotFoundError extends InternalError {
  constructor(message: string = 'Not found.', data?: Record<string, any>) {
    super(message, 404, data);
  }
}