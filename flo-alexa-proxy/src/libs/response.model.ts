import 'source-map-support/register';
import HttpError from './http.error';
import {envOrDefault, maybe, scrubFields} from "./utils";
import ContextError from './context.error';
import { CustomError } from 'ts-custom-error';
import ValidationError from './validation.error';

type DefinedError = HttpError | ValidationError | ContextError | CustomError
type NativeError = Error | RangeError | ReferenceError | SyntaxError | TypeError | URIError;
export type KnownError = DefinedError | NativeError;

export type ResponseHeader = { [header: string]: string | number | boolean; };
type ResponseBody = object | KnownError | string | maybe

interface IResponse {
    statusCode: number;
    headers: ResponseHeader;
    body: ResponseBody;
}

const RESPONSE_HEADERS: ResponseHeader = {
    'lambda-version': envOrDefault('GIT_HASH', 'unknown'), //NOTE: add whatever headers required here...
};

/**
 * Logic that wrap standard ApiGW lambda resp and error handling
 */
export default class ResponseModel implements IResponse {
    static Error<E extends KnownError>(err: E, code?: number): any {
        {
            let he = err as HttpError | maybe;
            if (HttpError.IsValidCode(he?.code)) {
                return new ResponseModel(he,he?.code ?? 500).generate();
            }
        }
        return new ResponseModel(err, HttpError.IsValidCode(code) ? code : 500).generate();
    }
    static ErrorMessage(message: string, code?: number): any {
        return this.Error(new HttpError(code ?? 0, message));
    }
    static ErrorCode(code: number, message?: string): any {
        return this.Error(new HttpError(code, message));
    }
    static Content(body: any, code = 200, headers?: ResponseHeader): any {
        return new ResponseModel(body, code, headers).generate();
    }
    static NoContent(code = 204, headers?: ResponseHeader): any {
        return new ResponseModel(null, code, headers).generate();
    }

    /** handle caught exception & auto translate into http response */
    static ErrorCatcher(e: any, note = '', httpCode = 0): any {
        let err: Error;
        if (!HttpError.IsValidCode(httpCode)) {
            httpCode = 500;
        }
        if (e instanceof ValidationError) {
            httpCode = 400;
            err = e as ValidationError;
        } else if (e instanceof ContextError) {
            const ctxErr = e as ContextError;
            if (note !== '') {
                if (ctxErr.note) {
                    ctxErr.note = `${note}: ${ctxErr.note ?? ''}`
                } else {
                    ctxErr.note = note;
                }
            }
            err = ctxErr;
        } else if (e instanceof Error) {
            let eStr = note;
            if (note !== '') {
                eStr += `: ${e.message}`;
            }
            err = new ContextError(eStr, { error: true, httpCode }, e).setNote(note);
        } else {
            switch (typeof e) {
                case 'string':
                    err = new ContextError(e, { note });
                    break;
                case 'number':
                    if (httpCode === 500 && HttpError.IsValidCode(e)) {
                        httpCode = e;
                    }
                    err = new ContextError('Error number: ' + e, { number: e, httpCode }).setNote(note);
                    break;
                case 'boolean':
                    err = new ContextError('Error boolean: ' + e, { boolean: e, httpCode }).setNote(note);
                    break;
                default:
                    let eStr = 'Unknown Error';
                    if (note !== '') {
                        eStr += `: ${note}`;
                    }
                    err = new ContextError(eStr, { source: e, httpCode }).setNote(note);
                    break;
            }
        }
        console.error('ResponseModel.ErrorCatcher', note, JSON.stringify(scrubFields(err)));
        return ResponseModel.Error(err, httpCode);
    }

    static IsValidCode(code: number | null): boolean {
        if (code === null) {
            return false;
        }
        return code >= 100 && code < 600;
    }

    readonly body: ResponseBody = {};
    readonly statusCode: number = 200;
    readonly headers: ResponseHeader = {};

    /**
     * ResponseModel Constructor
     */
    constructor(body: ResponseBody, code = 0, headers?: ResponseHeader) {
        this.body = body ?? '';
        this.statusCode = ResponseModel.IsValidCode(code) ? code : (this.body === '' ? 204 : 200);

        this.headers = headers ? { ...headers } : {}; //copies
        for (let k of Object.keys(RESPONSE_HEADERS)) { //ensure required headers
            if (!(k in this.headers)) { //check if missing
                this.headers[k] = `${RESPONSE_HEADERS[k]}`; //assign missing
            }
        }
    }

    generate(): any {
        const head = {
            'lambda-time': new Date().toISOString(),
            ...this.headers,
        };
        if (this.body) {
            const tn = typeof (this.body);
            switch (tn) {
                case 'string':
                    return {
                        statusCode: this.statusCode,
                        headers: { ...head },
                        body: this.body as string ?? '',
                    };
                case 'object':
                    let payload: Record<string, unknown> = {};
                    const body = this.body as any;
                    if (body) {
                        payload = { ...body };
                        if (body instanceof Error) { //extra error info
                            const err = this.body as Error;
                            if (err.name) {
                                payload.name = err.name;
                            }
                            if (err.message) {
                                payload.message = err.message;
                            }
                        }
                    }
                    return {
                        statusCode: this.statusCode,
                        headers: { ...head },
                        body: JSON.stringify(payload),
                    }
            }
        }

        let str = ''; //default case
        if (this.statusCode != 204) {
            str = '{}';
        }
        return {
            statusCode: this.statusCode,
            headers: { ...head },
            body: str,
        };
    }
}