import 'source-map-support/register';
import {ServiceConfigurationOptions} from "aws-sdk/lib/service";
import {APIVersions} from "aws-sdk/lib/config";

export type maybe = undefined | null;

// export function randomInt(max: number) {
//     return Math.floor(Math.random() * Math.floor(max));
// }

export function envOrDefault(envName: string, defaultVal: string) :string {
    let val = process.env[envName];
    if(val && val !== '') {
        return val;
    }
    return defaultVal;
}

export function envIsTrue(envName: string) :boolean {
    const val = envOrDefault(envName, '').toLowerCase();
    return val === 'true' || val === '1' || val.indexOf('enable')===0;
}

export function envOrThrow(envName: string) :string {
    let val = process.env[envName];
    if(val && val !== '') {
        return val;
    }
    throw new Error(`Missing environment variable: '${envName}'. `);
}

export type AwsCfg = ServiceConfigurationOptions & APIVersions;

export function ensureAwsConfig(cfg?: AwsCfg) :AwsCfg {
    if(!cfg) {
        cfg = { region: envOrDefault('AWS_REGION', '') };
    }
    if(!cfg.httpOptions) {
        cfg.httpOptions = {
            connectTimeout: 8000,
            timeout: 96000,
        };
    }
    if(/local/i.test(cfg.region ?? '')) {
        cfg.accessKeyId = 'local-access-id';
        cfg.secretAccessKey = 'local-secret-key';

        cfg.httpOptions.connectTimeout = 2000;
        cfg.httpOptions.timeout = 3000;
    }
    return cfg;
}

/** use to extract `--argument value` in command line input and if argument is not found, return default value */
export function argSpaceValOrDefault(argName: string, defaultVal: string, caseSensitive?:boolean) :string {
    if(!caseSensitive) {
        argName = argName.toLowerCase();
    }
    let found = false;
    for(let s of process.argv) {
        if(found) {
            return s;
        }
        if(!caseSensitive) {
            s = s.toLowerCase();
        }
        if(s === argName) {
            found = true;
        }
    }
    return defaultVal;
}

const JWT_RE = /^([a-z+=\/\d]{8,}).([a-z+=\/\d]{8,}).([a-z+=\/\d]{8,})$/i;
/** if jwt like, redact the signature portion **/
export function scrubJwt(token :string, redact?:string) :string {
    const rdt = redact ?? REDACT_STARS;
    if(JWT_RE.test(token)) {
        return token.replace(JWT_RE, (_,h,b) => `${h}.${b}.${rdt}`);
    }
    return rdt; //not typical JWT fmt, redact everything to be safe
}

const dirtyFields:string[] = [
    "correlationToken", "clientSecret", "authorizationCode", "token", "apiKey", "accessToken", "refreshToken", "authorizationCode",
    'password','authorization','pwd','secret'
];
export function scrubDirtyFields(obj:any):any {
    return scrubFields(obj, undefined, ...dirtyFields);
}

export type IMap<K extends number | string | symbol, V> = {
    [index in K]: V;
};

const REDACT_STARS = "******"
/** take a dirty input obj, return a new clean one **/
export function scrubFields(input:any, redact?:string, ...fields:string[]):any {
    const obj = marshalObj(input);
    if(!(fields?.length > 0)) {
        return obj;
    }
    if(obj && typeof obj == 'object') {
        const redactFields:IMap<string, boolean> = {};
        fields.forEach(v => {
            if(v.trim().length > 0) {
                redactFields[v.toLowerCase()]=true;
            }
        });
        return scrubLoop(obj, redact??REDACT_STARS, redactFields);
    }
    return obj;
}
function scrubLoop(obj:any, cover:string, redactMap:IMap<string, boolean>):any {
    if(obj && typeof obj == 'object') {
        const copy:any = {};
        for(const k of Object.keys(obj)) {
            let v:any = obj[k];
            if(v) {
                const t = typeof v;
                switch (t) {
                    case 'symbol':
                    case 'function':
                        v = undefined;
                        break;
                    case 'string':
                        if(redactMap[k.trim().toLowerCase()]) {
                            v = scrubJwt(`${v}`, cover);
                        }
                        break;
                    case 'object':
                        v = scrubLoop(v, cover, redactMap);
                        break;
                }
            }
            if(v) {
                copy[k] = v;
            }
        }
        return copy;
    }
    return obj;
}

/** force the impossible like Error class into obj */
export function marshalObj(o:any) :any {
    if(!o) {
        return o;
    }
    const alt:any = {};
    for(const k of Object.getOwnPropertyNames(o)) {
        let val:any = o[k];
        if(val) {
            switch (typeof val) {
                case 'object':
                    val = marshalObj(val);
                    break;
                case 'function':
                case 'symbol':
                    val = undefined;
                    break;
                default:
                    break; //return as is
            }
            if(val) {
                alt[k] = val;
            }
        }
    }
    return alt;
}

export class ReadTuple2<A, B> {
    readonly itemA:A;
    readonly itemB:B;
    constructor(a:A, b:B) {
        this.itemA = a;
        this.itemB = b;
    }
    toArray() :any[] {
        return [this.itemA, this.itemA];
    }
}

export function tryConvJson(o:any):ReadTuple2<any, boolean> {
    try {
        if(o) {
            switch(typeof(o)) {
                case 'object':
                    return new ReadTuple2(o as any, true);
                case 'string':
                    const str = o as string;
                    if (str.length > 1 && str[0] === '{' && str[str.length - 1] === '}') {
                        const ro = JSON.parse(str);
                        if (ro) {
                            return new ReadTuple2(ro, true);
                        }
                    }
                    break;
            }
        }
    }catch (e) {
        const ctx = scrubFields({ error:e, input:o });
        console.warn('tryConvJson', ctx);
    }
    return new ReadTuple2(o, false);
}