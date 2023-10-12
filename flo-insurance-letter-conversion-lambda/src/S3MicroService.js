const AWS = require('aws-sdk');
const uuid = require('uuid');
const bucketName = process.env.S3_BUCKET;

class S3MicroService {


  uploadPdf(file, fileName) {
    const params = {
      Bucket: bucketName,
      Key: fileName,
      Body: file
    };
    return new Promise((resolve, reject) => {
      new AWS.S3().upload(params, function (err, data) {
        if (err) {
          reject(err);
        }
        resolve(data);
      });
    });
  }
}

module.exports = S3MicroService;


