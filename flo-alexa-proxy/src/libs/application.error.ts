import ContextError from './context.error';

/**
 * General application exception wrapper with context & optional error code
 */
export default class ApplicationError extends ContextError {
    code?: string = undefined; //can be any predefined code

    setCode(code: string): ApplicationError {
        this.code = code;
        return this;
    }

    toString(): string {
        return `CODE::${this.code ?? 'NONE'} - ${super.toString()}`;
    }
}