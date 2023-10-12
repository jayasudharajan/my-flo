const AWS = require('aws-sdk');

const docClient = new AWS.DynamoDB.DocumentClient();
const table = process.env.DYNAMO_INSURANCE_LETTER_REQUEST_LOG

class DynamoMicroService {
  writeLogRecord(record) {

    return new Promise((resolve, reject) => {
      docClient.update(this._getParams(record), function (err, data) {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  _getParams(record) {
    return {
      TableName: table,
      Key: {
        'location_id': record.location_id,
        'created_at': record.created_at
      },
      UpdateExpression: 'set generated_at = :g, s3_bucket = :s3b, s3_key = :s3k, s3_location_url = :s3l',
      ExpressionAttributeValues: {
        ':g': record.generated_at,
        ':s3b': record.s3_bucket,
        ':s3k': record.s3_key,
        ':s3l': record.s3_location
      },
      ReturnValues: "UPDATED_NEW"
    };
  }

}

module.exports = DynamoMicroService;