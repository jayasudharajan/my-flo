import 'source-map-support/register';
import {envIsTrue, envOrDefault} from "@libs/utils";
import {IAlexaService} from "@libs/services/alexa.service";

export enum PingLevel {
    Unknown = '',
    Shallow = 'Shallow',
    Deep = 'Deep',
}

export class PingResponse {
    readonly name: string = 'flo-alexa-proxy';
    readonly stage: string = envOrDefault('STAGE', '0-stage');
    readonly region: string = envOrDefault('REGION', '0-region');
    readonly hash: string = envOrDefault('GIT_HASH', '0-hash');
    readonly branch: string = envOrDefault('GIT_BRANCH', '0-branch');
    readonly commitAt: string = envOrDefault('GIT_TIME', '1980-01-01T00:00:00Z');
    readonly now: Date = new Date();
    status: string = 'OK';
    depth?: PingLevel = undefined;
    target?: string = undefined;
    relay?: IPingRelay = undefined;
}

export interface IPingRelay {
    func:string,
    input?:any,
    output?:any,
}

class PingRelay implements IPingRelay {
    readonly func:string;
    input?:any = undefined;
    output?:any = undefined;
    constructor(func:string) {
        this.func = func;
    }
}

export interface IPingService {
    ping(depth?:PingLevel) :Promise<PingResponse>
}

export class PingService implements IPingService {
    private static helpIntentReq(): any {
        return {
            session: {
                application: { applicationId: envOrDefault('ALEXA_APPLICATION_ID', 'unknown-skill') },
            },
            request: {
                type: 'IntentRequest',
                intent: { name: 'AMAZON.HelpIntent' },
            },
        };
    }
    private static pingReq(): any {
        return { request: { type: 'PingRequest' } };
    }
    private static pingSmartHomeReq(deep?:boolean): any {
        const pr = this.pingReq();
        pr.request.smartHome = true;
        if(deep === true) {
            pr.request.deep = true;
        }
        return pr;
    }

    readonly alexa?:IAlexaService;
    constructor(alexa?:IAlexaService) {
        this.alexa = alexa;
    }

    async ping(depth?:PingLevel, target?:string) :Promise<PingResponse> {
        const res = new PingResponse();
        if(depth) {
            res.depth = depth;
            res.target = target;
            const smartHomeTarget = target && target.toLowerCase() === 'smarthome';
            if(this.alexa) {
                res.relay = new PingRelay(this.alexa.funcName);
                switch (depth) {
                    case PingLevel.Shallow: //call help intent
                        if(envIsTrue('ALEXA_LAMBDA_PING')) {
                            res.relay.input = smartHomeTarget ? PingService.pingSmartHomeReq(false) : PingService.pingReq();
                        } else {
                            res.relay.input = PingService.helpIntentReq();
                        }
                        break;
                    case PingLevel.Deep:
                        res.relay.input = smartHomeTarget ? PingService.pingSmartHomeReq(true) : PingService.helpIntentReq();
                        break;
                }
                try {
                    res.relay.output = await this.alexa.invoke(res.relay.input);
                } catch (e) {
                    res.relay.output = e;
                    res.status = 'Ping Failure';
                }
            }
        }
        return Promise.resolve(res);
    }
}