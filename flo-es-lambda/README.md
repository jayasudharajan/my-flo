# flo-es-lambda

## Architecture

https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/1306001409/Flo+ElasticSearch+Sync+Lambda

## How to Deploy

1. Run `bash package.sh`
2. This will create a `es-lambda.zip` archive
3. Go to AWS Lambda console, select Lambda function that corresponds to the correct DynamoDB stream, and upload the `es-lambda.zip` archive

## Env Vars


| Variable | Descriptipon |
| ------ | ------ |
| `environment` | The environment prefix to be used for DynamoDB (`dev` for development, `prod` for production) |
| `ELASTICSEARCH_HOST` | Address of elasticsearch instance. Credentials are included here. |
| `S3_BUCKET_NAME` | Name of S3 bucket for encryption key (DEPRECATED) |
| `S3_BUCKET_REGION` | Region of S3 bucket for encryption key (DEPRECATED) |
| `S3_KEY_PATH_TEMPLATE` | Template for key in the S3 bucket for encryption key (DEPRECATED) |

The DEPRECATED environment variables are no longer in use since migrating away from client-side encryption in DynamoDB.