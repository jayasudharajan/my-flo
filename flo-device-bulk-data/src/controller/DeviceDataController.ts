import { Context, APIGatewayEvent, APIGatewayProxyHandler, APIGatewayProxyResult, APIGatewayProxyCallback } from 'aws-lambda';
import moment from 'moment';
import S3Client from '../s3/S3Client';
import { StockICD, SignedBlobHeader, HeadFileParameters, DateTime, FileType } from '../model/interfaces';
import config from '../config/config';
import DynamoDbService from '../dynamo/DynamoDbService';
import BaseController from './BaseController';
import AuthorizationService from '../authorization/AuthorizationService';

const fileType = {
  TELEMETRY: 'tlm',
  TELEMETRY_LONG: 'telemetry',
  LOG: 'log'
};

// used to validate head endpoint param values
const pathTypes = [
  'telemetry',
  'logs'
];

const _watchList = new Map<string, string>(); //SEE: SNTY-292 for context

let _watchListInit = 0;
function watchListInit(envVar: string): void {
  if (_watchListInit == 0) {
    const csv = envVar.split(',') || [];
    const macRe = /^[a-f0-9]{12}$/i; //587a62320ffc
    const dtRe = /^(20[2-9][0-9])([0,1][0-9])([0-3][0-9])(T[0-2][0-9][0-5][0-9]|)$/i; //fmt: yyyyMMddThhmm
    const pathStart = '/v8.lf.csv.gz/'; //will reject LF only for now
    csv.forEach(s => {
      const pair = s?.split('|');
      const pairCount = pair?.length || 0;
      if (pairCount === 1 && macRe.test(pair[0])) {
        _watchList.set(pair[0].toLowerCase(), pathStart);
      } else if (pairCount >= 2) {
        const mac = pair[0];
        const dt = pair[1];
        if (macRe.test(mac)) {
          const validDt = dtRe.test(dt);
          if (dt === '' || validDt) {
            let pathMatch = pathStart; ///v8.lf.csv.gz/year=2022/month=04/day=21/hhmm=2005
            if (validDt) {
              const arr = dtRe.exec(dt) || [];
              if (arr.length >= 4) {
                pathMatch += `year=${arr[1]}/month=${arr[2]}/day=${arr[3]}/`; //entire day rejection
                if (arr.length >= 5 && arr[4].length === 5) {
                  pathMatch += `hhmm=${arr[4].substring(1)}/`; //specific 5min block rejection
                }
              }
            }
            _watchList.set(mac.toLowerCase(), pathMatch);
          }
        }
      }
    });
    _watchListInit = 1;
    _watchList.forEach((v, k) => console.log(`watchListInit: set ${k} -> ${v}`));
  }
}

function watchListMatch(mac: string, path = ''): boolean {
  mac = mac?.toLowerCase();
  if (_watchList.has(mac)) {
    const mt = _watchList.get(mac) || ''; //reject everything from matching mac by default if there are no dt configured
    if (mt.length > 0) {
      path = path?.toLowerCase() || '';
      return path.indexOf(mt) >= 0;
    }
    return true;
  }
  return false;
}

class DeviceDataController extends BaseController {
  //files uploaded older than this time period will be checked for duplicates
  readonly pastHrDedupeChk: number = 6; //SEE: for more context, see https://gpgdigital.atlassian.net/browse/FLOSWS-156

  constructor(
    private s3Client: S3Client,
    private dynamoDbService: DynamoDbService,
    private authorizationService: AuthorizationService
  ) {
    super();
    watchListInit(process.env.DEVICE_TELEMETRY_REJECT || '');

    const hr = parseInt(process.env.PAST_HR_DEDUPE_CHK || '');
    this.pastHrDedupeChk = hr > 0 ? hr : this.pastHrDedupeChk;
  }

  public postTelemetryData: APIGatewayProxyHandler = async (_event: APIGatewayEvent, _context: Context, _done: APIGatewayProxyCallback): Promise<APIGatewayProxyResult> => {
    if (!config.telemetryS3Bucket) {
      throw new Error("Required TELEMETRY_S3_BUCKET env var is missing");
    }
    const filename = `{$MAC_ADDRESS}.{$SIGNATURE}.{$DATA_VERSION}${config.s3FileExtension}`;
    const type: FileType = FileType.Telemetry;
    return this.processRequest(_event, _context, _done, config.telemetryS3Bucket, filename, type)
  }

  public postLogsData: APIGatewayProxyHandler = async (_event: APIGatewayEvent, _context: Context, _done: APIGatewayProxyCallback): Promise<APIGatewayProxyResult> => {
    if (!config.logsS3Bucket) {
      throw new Error("Required LOGS_S3_BUCKET env var is missing");
    }
    const filename = `{$MAC_ADDRESS}-{$SIGNATURE}.${fileType.LOG}.gz`;
    const type: FileType = FileType.Logs;
    return this.processRequest(_event, _context, _done, config.logsS3Bucket, filename, type)
  }

  private shouldCheckDuplicate(_event: APIGatewayEvent, dt: DateTime): boolean {
    if (_event.queryStringParameters && _event.queryStringParameters['deduplicate'] === 'true') {
      return true;
    }
    const hr = moment().diff(dt, 'hours', true);
    return hr > this.pastHrDedupeChk;
  }

  private processRequest = async (_event: APIGatewayEvent, _context: Context, _done: APIGatewayProxyCallback, bucket: string,
    filename: string, type: FileType): Promise<APIGatewayProxyResult> => {
    try {
      const header = this.getHeaderInfo(_event, type)
      console.log('header', header)
      const clientKeys = await this.dynamoDbService.getPrivateKeyByMacAddress(header.macAddress)
      if (!clientKeys) {
        return this.sendNotFoundResponse(`Mac address ${header.macAddress} was not found.`)
      }
      if (!_event.body) {
        return this.sendBadRequestResponse('Empty body: A file must be provided');
      }

      const enc = _event.isBase64Encoded || process.env.FORCE_BASE64_UPLOAD === 'true' ? 'base64' : 'binary';
      const content = Buffer.from(_event.body, enc);
      if (!this.isValidSignature(content, clientKeys, header)) {
        return this.sendUnauthorizedResponse();
      }

      const s3FilenamePostfix = filename
        .replace('{$MAC_ADDRESS}', header.macAddress)
        .replace('{$SIGNATURE}', header.signature)
        .replace('{$DATA_VERSION}', header.dataVersion);

      const pathPrefixS3 = this.buildS3prefix(type, header.macAddress, header.dataVersion)
      const fileKey = this.s3Client.buildKey(pathPrefixS3, s3FilenamePostfix, header.macAddress, type, header.startDate);
      if (watchListMatch(fileKey)) { //reject file upload here, SEE: SNTY-292 for context
        console.warn(`KEY_DENIAL: upload rejected | ${bucket} | ${fileKey}`);
        return this.sendForbiddenResponse();
      }
      if (this.shouldCheckDuplicate(_event, header.startDate)) {
        const isDuplicate = await this.s3Client.keyExists(fileKey, bucket);
        if (isDuplicate) {
          console.warn(`KEY_DUPLICATE: upload rejected | ${bucket} | ${fileKey}`);
          return this.sendConflictResponse();
        }
      }
      await this.s3Client.uploadFile(content, fileKey, bucket);
      console.log(`UPLOAD_DONE sig=${header.signature} | ${fileKey}`);
      return this.sendSuccessResponse();
    } catch (e) {
      const error = e as Error;
      const newError = new Error('Error processing API Gateway request: ' + error?.message);
      newError.stack += `\n${error?.stack}`
      throw newError
    }
  }

  private buildS3prefix(type: FileType, macAddress: string, dataVersion: string): string {
    // built this way to shard by the first 7 characters of the key
    // fileType.TELEMETRY must be 3 characters long maximum
    if (type === FileType.Telemetry) {
      const shard = macAddress.slice(-2);
      return `${fileType.TELEMETRY}-${shard}/v${dataVersion}/`
    }

    if (type === FileType.Logs)
      return `${fileType.LOG}/`

    return "unknown"
  }

  private buildOldS3prefix(type: FileType, dataVersion: string): string {
    if (type === FileType.Telemetry)
      return `${fileType.TELEMETRY_LONG}-v${dataVersion}/`

    if (type === FileType.Logs)
      return `${fileType.LOG}/`

    return "unknown"
  }

  private isValidSignature(content: Buffer, clientKeys: StockICD, header: SignedBlobHeader): boolean {
    const decodedKey = Buffer.from(clientKeys.icd_client_key, 'base64');
    const signature = this.authorizationService.signBlobContent(content, decodedKey.toString())
    const validSig = signature === header.signature; //allow local debugger to override variable for easy debugging
    if (!validSig) {
      console.warn('isValidSignature: SIGNATURE_INVALID should have been', signature, 'for', clientKeys.device_id);
    } else {
      console.log('isValidSignature: SIGNATURE_OK', signature, 'for', clientKeys.device_id);
    }
    return validSig
  }

  private getHeaderInfo(event: APIGatewayEvent, type: FileType): SignedBlobHeader {
    let startDate: DateTime = moment().startOf('minute').utc();
    let dataVersion = '0';
    if (type === FileType.Telemetry) {
      const dtStr = event.headers['x-data-startdate'];
      if (!dtStr || !(moment(dtStr).isValid())) {
        console.warn('Header[x-data-startdate]: BAD_START_DATE.'); //Empty or invalid date
      } else {
        startDate = moment(dtStr).startOf('minute').utc();
        //startDate = startDate.minute(startDate.minute() - (startDate.minute() % 5)); //floor to the nearest minute
      }
      if (!event.headers['x-data-version']) {
        console.warn('Header[x-data-version]: Missing data version header..');
      } else {
        dataVersion = event.headers['x-data-version'];
      }
    }
    return {
      macAddress: event.headers['x-flo-device-id'] || '',
      signature: event.headers['x-flo-signature'] || '',
      signatureType: event.headers['x-flo-signature-type'] || '',
      startDate,
      dataVersion
    }
  }

  public headFile: APIGatewayProxyHandler = async (_event: APIGatewayEvent, _context: Context, _done: APIGatewayProxyCallback): Promise<APIGatewayProxyResult> => {
    try {
      console.log("Fetching file info")
      console.log(_event.queryStringParameters)
      const params = this.validateHeadFileParameters(_event)
      if (typeof params === 'string') {
        return this.sendBadRequestResponse(params)
      }
      const type = (params.type === 'telemetry') ? FileType.Telemetry : FileType.Logs
      const bucket = (type === FileType.Telemetry) ? config.telemetryS3Bucket || "" : config.logsS3Bucket || "";
      const s3FilenamePostfix = (type === FileType.Telemetry) ?
        `${params.macAddress}.${params.signature}.${params.dataVersion}${config.s3FileExtension}` :
        `${params.macAddress}-${params.signature}.${fileType.LOG}.gz`;

      const resultCurrent: Boolean =
        await this.s3Client.fileExists(this.buildS3prefix(type, params.macAddress, params.dataVersion), s3FilenamePostfix, bucket, params.macAddress, params.createdAt, type);
      if (resultCurrent)
        return this.sendSuccessResponse();

      const resultPrevious: Boolean =
        await this.s3Client.fileExists(this.buildOldS3prefix(type, params.dataVersion), s3FilenamePostfix, bucket, params.macAddress, params.createdAt, type);
      if (resultPrevious)
        return this.sendSuccessResponse();

      console.log("File not found")
      return this.sendNotFoundResponse('File not found')
    } catch (e) {
      const error = e as Error;
      const newError = new Error('Error retrieving file: ' + error?.message);
      newError.stack += `\n${error?.stack}`
      throw newError
    }
  }

  private validateHeadFileParameters(_event: APIGatewayEvent): HeadFileParameters | string {
    if (!config.logsS3Bucket) {
      throw new Error("Required LOGS_S3_BUCKET env var is missing");
    }
    if (!config.telemetryS3Bucket) {
      throw new Error("Required TELEMETRY_S3_BUCKET env var is missing");
    }
    if (!_event.pathParameters || !_event.pathParameters.type) {
      return 'Required type path parameter missing';
    }
    if (!pathTypes.includes(_event.pathParameters.type)) {
      return 'type path parameter must be either "telemetry" or "logs"';
    }
    if (!_event.queryStringParameters || !_event.queryStringParameters.macAddress) {
      return 'Required macAddress parameter is missing.';
    }
    if (!_event.queryStringParameters.signature) {
      return 'Required signature parameter is missing.';
    }
    if (!_event.queryStringParameters.createdAt) {
      return 'Required createdAt parameter is missing.';
    }
    return {
      type: _event.pathParameters.type,
      macAddress: _event.queryStringParameters.macAddress,
      signature: _event.queryStringParameters.signature,
      createdAt: _event.queryStringParameters.createdAt,
      dataVersion: _event.queryStringParameters.dataVersion || '0'
    }
  }
}

export default DeviceDataController