export default {
  environment: process.env.ENVIRONMENT,
  tablePrefix: process.env.TABLE_PREFIX,
  accountId: process.env.ACCOUNT_ID,
  telemetryS3Bucket: process.env.TELEMETRY_S3_BUCKET,
  logsS3Bucket: process.env.LOGS_S3_BUCKET,
  s3FileExtension: process.env.S3_FILE_EXTENSION,
};