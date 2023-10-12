import ContextError from "@libs/context.error";

export default class LambdaError extends ContextError {
    statusCode?: number = undefined;
    constructor(message:string, context?: any, statusCode?:number) {
        super(message, context);
        this.statusCode = statusCode;
    }

    setStatusCode(statusCode?:number) :LambdaError {
        this.statusCode = statusCode;
        return this;
    }
}