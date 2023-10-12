import { CustomError } from 'ts-custom-error';
import {maybe} from "@libs/utils";

/**
 * Database exception wrapper that provides more context.
 */
export default class ContextError extends CustomError {
    /** additional context if available */
    readonly context: any;
    /** wrapped original error */
    readonly source: Error | maybe;
    /** optional notes */
    note?: string = undefined; //optional note

    constructor(message: string | maybe, context?: any, source?: Error) {
        super(message ?? 'Context Error');

        Object.defineProperty(this, 'name', { value: this.name, writable: true }); //fix missing name in marshaling
        this.context = context;
        this.source = source;
    }

    setNote(note: string): ContextError {
        this.note = note;
        return this;
    }

    toString(): string {
        let msg = this.message;
        if (this.context && Object.keys(this.context).length > 0) {
            msg += `\n\tcontext: ${JSON.stringify(this.context)}`;
        }
        if (this.note && this.note !== '') {
            msg += `\n\tnote: ${JSON.stringify(this.note)}}`;
        }
        if (this.source) {
            msg += `\n\tsource: ${JSON.stringify(this.source)}`;
        }
        return msg;
    }
}