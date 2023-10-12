

function handleS3GetObject(deferred) {
  return (err, data) => {
    if (err) {
      deferred.reject(err);
    } else {
      deferred.resolve(data);
    }
  }
}

class S3Utils {

  constructor(s3) {
    this.s3 = s3;
  }

  retrieveFile(bucket, key) {
    const deferred = Promise.defer();

    this.s3.getObject(
      { Bucket: bucket, Key: key },
      handleS3GetObject(deferred)
    );

    return deferred.promise.then(file => file.Body);
  }
}

export default S3Utils;