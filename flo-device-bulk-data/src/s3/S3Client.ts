import AWS from 'aws-sdk';
import moment from 'moment';
import { DateTime, FileType } from '../model/interfaces';

export default class S3Client {
  private s3: AWS.S3

  constructor(
  ) {
    this.s3 = new AWS.S3()
  }

  public buildKey(pathPrefix: string, fileNamePostfix: string,
    macAddress: string, type: FileType, startDate: DateTime): string {
    return pathPrefix + this.getPath(fileNamePostfix, macAddress, startDate, type);
  }

  public uploadFile(file: any, fileKey: string, bucket: string): Promise<any> {
    const params = {
      Bucket: bucket,
      Key: fileKey,
      Body: file
    };
    return new Promise((resolve, reject) => {
      this.s3.upload(params, function (err: any, data: any) {
        if (err) {
          reject(err);
        }
        resolve(data);
      });
    });
  }

  public async keyExists(fileKey: string, bucket: string): Promise<Boolean> {
    const params = { Bucket: bucket, Key: fileKey };
    try {
      await this.s3.headObject(params).promise();
      return true;
    } catch (e) {
      const error = e as any;
      if (error?.statusCode === 404) {
        return false;
      }
      console.error(error);
      throw error;
    }
  }

  public async fileExists(pathPrefix: string, fileNamePostfix: string, bucket: string, macAddress: string,
    createdAt: string, type: FileType): Promise<Boolean> {
    const fileKey: string = pathPrefix + this.getPath(fileNamePostfix, macAddress, moment(createdAt), type);
    return await this.keyExists(fileKey, bucket);
  }

  private getPath(fileName: string, macAddress: string, createdAt: DateTime = moment(), type: FileType): string {
    createdAt = createdAt.startOf('minute').utc(); //floor to the nearest minute
    const date = createdAt.format('YYYYMMDD');
    if (type === FileType.Logs) {
      return `year=${createdAt.format('YYYY')}/month=${createdAt.format('MM')}/day=${createdAt.format('DD')}/device=${macAddress}/${date}-${fileName}`;
    } else if (type === FileType.Telemetry) {
      //createdAt = createdAt = createdAt.minute(createdAt.minute() - (createdAt.minute() % 5)); //floor to the nearest minute
      return `year=${createdAt.format('YYYY')}/month=${createdAt.format('MM')}/day=${createdAt.format('DD')}/hhmm=${createdAt.format('HH')}${createdAt.format('mm')}/deviceid=${macAddress}/${fileName}`;
    } else {
      return fileName;
    }
  }
}