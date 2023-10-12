import { CustomError } from 'ts-custom-error';

type codeMap = { [index: number]: string };

export default class HttpError extends CustomError {
    /**
     * @see:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
     */
    static readonly Codes: codeMap = {
        400: 'Bad Request',
        401: 'Unauthorized',
        402: 'Payment Required',
        403: 'Forbidden',
        404: 'Not Found',
        405: 'Method Not Allowed',
        406: 'Not Acceptable',
        407: 'Proxy Authentication Required',
        408: 'Request Timeout',
        409: 'Conflict',
        410: 'Gone',
        421: 'Misdirected Request',
        423: 'Locked',
        424: 'Failed Dependency',
        428: 'Precondition Required',
        429: 'Too Many Requests',
        431: 'Request Header Fields Too Large',
        451: 'Unavailable For Legal Reasons',

        500: 'Internal Server Error',
        501: 'Not Implemented',
        502: 'Bad Gateway',
        503: 'Service Unavailable',
        504: 'Gateway Timeout',
        505: 'Http Version Not Supported',
        507: 'Insufficient Storage',
        511: `Notwork Authentication Required`,
    };

    static Status(code: number): string {
        return this.Codes[code] ?? 'Unknown Error';
    }

    static IsValidCode(code?: number): boolean {
        if (code) {
            return code >= 400 && code < 600;
        }
        return false;
    }

    readonly code: number;
    /**
     * Represent an http error
     * @param code optional http error code, 500 default. @see:HttpError.Codes
     * @param message optional message, default to standard http status.
     */
    constructor(code: number, message?: string | null) {
        const c = code >= 400 && code < 600 ? code : 500;
        const msg = message == null || message.trim() == '' ? HttpError.Status(c) : message;
        super(msg);
        Object.defineProperty(this, 'name', { value: this.name, writable: true }); //fix missing name in marshaling

        this.code = c;
    }

    toString(): string {
        return `${this.code} - ${this.message}`; //standard read
    }
}