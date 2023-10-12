const RequestHandler = require('./RequestHandler');
const { v4: uuidv4 } = require('uuid');

/**
 * Custom ping response, not part of Alexa Skill or SmartHome spec, for Flo internal health check & debug use only
 */
class PingHandler extends RequestHandler {
    constructor(axios, smartHomeUrl, applicationId) {
        super();
        this.axios = axios;
        this.smartHomeUrl = smartHomeUrl;
        this.appId = applicationId;
    }

    handleEvent(evt) {
        if(evt.request.smartHome === true) {
            const pingDirective = { //create a ping directive & proxy response from flo-alexa-smarthome svc
                directive: {
                    header: { namespace: 'flo', name: 'ping', deep: evt.request.deep === true }
                }
            };
            return new DirectiveHandler(this.axios, this.smartHomeUrl).handleEvent(pingDirective)
                .then(resp => Promise.resolve(resp))
                .catch(err => Promise.reject(err));
        }

        //else, do standard ping
        const pongResp = this.createSpeechletResponse('Pong');
        const commitHash = process.env.COMMIT_HASH ? process.env.COMMIT_HASH : 'no-hash';
        const floApi = process.env.FLO_API_URL ? process.env.FLO_API_URL : 'http://localhost:8080/api';
        return Promise.resolve(
            this.createResponse(Object.assign({ commitHash, floApi, applicationId: this.appId }, pongResp))
        );
    }
}

/**
 * Proxy request to our flo-Alexa-SmartHome service n expected format: POST ./lambda/{namespace}/{action}/{request-id}
 */
class DirectiveHandler {
    constructor(axios, url) {
        this.axios = axios;
        this.url = url;
        const tms = parseInt(process.env.HTTP_REQ_TIMEOUT_MS) || 0;
        this.timeout = tms > 0 ? tms : 4750;
    }

    buildReq(evt) {
        const name = (evt.directive.header?.name || '').toLowerCase();
        if(name === '') { //this is always required!
            console.warn('DirectiveHandler.buildReq: name field is empty or missing from header', evt.directive)
            return undefined;
        }

        let messageId;
        let hasId = false;
        if(evt.directive.header.messageId?.length > 0) {
            messageId = evt.directive.header.messageId;
            hasId = true;
        } else {
            const uuid = uuidv4();
            messageId = uuid.replace(/-/gi, '');
            evt.directive.header.messageId = messageId;
        }

        let url = '';
        const ns = (evt.directive.header?.namespace || '').toLowerCase();
        if(ns === '' || ns === 'flo') {
            if(name === 'ping') {
                if(evt.directive.header.deep === true) {
                    return { method: 'POST', url:`${this.url}/${name}`, data: {} };
                } else {
                    return { method: 'GET', url:`${this.url}/${name}` };
                }
            }
            if(hasId) {
                url = `${this.url}/${name}/${messageId}`;
            } else {
                url = `${this.url}/${name}`;
            }
        } else {
            url = `${this.url}/lambda/${ns}/${name}/${messageId}`;
        }
        return { method: 'POST', url, data: evt, timeout: this.timeout };
    }

    buildResp(resp) {
        // const code = resp?.status && parseInt(resp.status) || 0;
        // if(code >= 400 && code <= 599) {
        //     throw resp.data;
        // } else {
        //     return resp.data || {};
        // }
        return resp.data || {};
    }

    async handleEvent(evt) {
        let op = undefined;
        try {
            op = this.buildReq(evt);
        } catch (e) {
            throw new DirectiveConstructionError(evt, e);
        }
        if(!op) {
            throw new DirectiveConstructionError(evt, new DomainError('DirectiveHandler.handleEvent can\'t buildReq'));
        }

        try {
            const resp = await this.axios(op);
            const code = resp?.status && parseInt(resp.status) || 0;
            if(code >= 400 && code <= 599) {
                if(code >= 500) {
                    console.error('DirectiveHandler.handleEvent', op, '=>', resp);
                } else {
                    console.warn('DirectiveHandler.handleEvent', op, '=>', resp);
                }
            } else {
                console.debug('DirectiveHandler.handleEvent: OK', op, '=>', resp);
            }
            return this.buildResp(resp);
        } catch (e) {
            let code = 500;
            if(e?.status) {
                code = parseInt(e.status);
            } else if (e?.response?.status) {
                code = e.response.status;
            }
            if(code < 400 || code > 599) {
                code = 500;
            }
            if(e?.response?.data && Object.keys(e.response.data)?.length > 0) {
                if(code >= 400 && code < 500) {
                    console.warn('DirectiveHandler.handleEvent', op, '=>', e.response.data);
                } else {
                    console.error('DirectiveHandler.handleEvent', op, '=>', e.response.data);
                }
                return this.buildResp(e.response);
            }
            throw new DirectiveExecuteError(op, e, code);
        }
    }
}

class DomainError extends Error {
    constructor(message, code) {
        if(code < 400 || code > 599) {
            code = 500;
        }
        super(message);
        this.name = this.constructor.name;
        Error.captureStackTrace(this, this.constructor); //clip stack trace, SEE: https://rclayton.silvrback.com/custom-errors-in-node-js
        Error.stackTraceLimit = 1;
        this.code = code;
    }
}

class DirectiveConstructionError extends DomainError {
    constructor(evt, err) {
        const msg = err?.message || 'no info';
        super(`Directive request construction failed: ${msg}`, 400);
        this.data = { event:evt, error:err };
    }
}

class DirectiveExecuteError extends DomainError {
    constructor(req, err, code) {
        const msg = err?.message || 'no info';
        super(`Directive execution failed: ${msg} | ${JSON.stringify(req)}`, code);
        this.data = { request:req, error:err };
    }
}

module.exports = { PingHandler, DirectiveHandler, DomainError, DirectiveExecuteError, DirectiveConstructionError };