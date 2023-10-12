import 'source-map-support/register';
import * as AWS from 'aws-sdk';
import LambdaError from "@libs/lambda.error";
import {ensureAwsConfig, marshalObj, maybe, tryConvJson} from "@libs/utils";

export type GoatConfig = AWS.Lambda.Types.ClientConfiguration; //quick alias
type GoatReq = AWS.Lambda.InvocationRequest
type GoatResp = AWS.Lambda.InvocationResponse

export type AlexaRequest = any;
export interface IAlexaResponse {
    StatusCode?: number,
    Payload?: any,
    ExecutedVersion?: string,
}

export interface IAlexaService {
    funcName:string,
    invoke(req: AlexaRequest) :Promise<IAlexaResponse>,
}

export class AlexaService implements IAlexaService {
    readonly funcName: string = '';
    private readonly cfg: GoatConfig;
    private readonly goat: AWS.Lambda;

    constructor(funcName: string, cfg? :GoatConfig) {
        if(!funcName || funcName.length == 0) {
            throw new LambdaError('functionName is required');
        }

        this.cfg = ensureAwsConfig(cfg) as GoatConfig;
        const arnRe = /^arn:aws:lambda:([^:]+)/i;
        if(arnRe.test(funcName)) {
            const parts = arnRe.exec(funcName);
            if(parts && parts.length >= 2 && parts[1]?.length > 0) {
                this.cfg.region = parts[1];
            }
        } else { //support local lambda instance for debugging. SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4505
            const localRe = /^(http[s]?:\/\/[^\/]+)\/(.+)$/i;
            const parts = localRe.exec(funcName);
            if(parts && parts.length >= 3 && parts[2]?.length > 0) {
                this.cfg.endpoint = parts[1];
                this.cfg.sslEnabled = this.cfg.endpoint.indexOf("https:") === 0;
                this.cfg.region = 'local';
                funcName = parts[2];
            }
        }
        this.funcName = funcName;
        this.goat = new AWS.Lambda(this.cfg);
    }

    public async invoke(body: AlexaRequest) :Promise<IAlexaResponse> {
        const req :GoatReq = { FunctionName: this.funcName, Payload: JSON.stringify(body) };
        let err :LambdaError|maybe = undefined;
        let resp :GoatResp|maybe = undefined;
        try {
            const cb = this.goat.invoke(req);
            resp = await cb.promise();
            if(resp.FunctionError && resp.FunctionError !== '') {
                const pt = tryConvJson(resp.Payload);
                const ctx = { request: body, lambda: this.funcName, cfg: this.cfg, error:resp.FunctionError, payload:pt.itemA };
                err = new LambdaError('alexa-invoke', ctx, resp.StatusCode);
            } else {
                const pt = tryConvJson(resp.Payload);
                if(pt.itemB) {
                    const ExecutedVersion = resp.ExecutedVersion ?? '$LATEST';
                    return { StatusCode: resp.StatusCode, ExecutedVersion, Payload: pt.itemA };
                }
            }
        } catch (e) {
            const ctx = { request: body, lambda: this.funcName, cfg: this.cfg, src: marshalObj(e) };
            err = new LambdaError('alexa-invoke-catch', ctx);
        }
        if(err || !resp) {
            throw err;
        }
        const ctx = { request: body, error:'payload is not of type JSON or body is missing', payload: resp.Payload };
        throw new LambdaError('alexa-invoke-parse', ctx);
    }
}