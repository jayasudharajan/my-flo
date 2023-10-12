import AWS from 'aws-sdk'

export class S3Client {
  protected client: AWS.S3

  constructor() { this.client = new AWS.S3(); }

  public async put(location: string, filename: string, contents: string): Promise<AWS.S3.Types.PutObjectOutput> {
    return new Promise((resolve, reject) => {

      const request: AWS.S3.Types.PutObjectRequest = {
        Bucket: location,
        Key: filename,
        Body: contents,
      }

      this.client.putObject(request, (error, data) => {
        if (error) {
          return reject(error)
        }

        return resolve(data)
      })
    })
  }
}
