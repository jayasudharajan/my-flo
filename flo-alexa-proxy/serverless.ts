import 'source-map-support/register';
import type { AWS } from '@serverless/typescript';

import proxy from '@functions/proxy';
import {argSpaceValOrDefault, envOrDefault} from "@libs/utils";

const DEFAULT_ALEXA_LAMBDA = 'arn:aws:lambda:us-west-2:098786959887:function:flo-alexa-dev';
const DEFAULT_ALEXA_APPLICATION_ID = 'amzn1.ask.skill.d084a806-bcff-4ef8-b9b6-3261a0d70f13';
const localProxyPort = parseInt(envOrDefault('FLO_ALEXA_PROXY_PORT', '5000'));

const serverlessConfiguration: AWS = {
  service: 'flo-alexa-proxy',
  frameworkVersion: '>=2.31.0',
  disabledDeprecations: [
    'AWS_API_GATEWAY_SCHEMAS',
  ],
  custom: {
    ['serverless-offline']: {
      httpPort: localProxyPort,
      lambdaPort: localProxyPort+2,
      babelOptions: {
        presets: ["env"],
      }
    },
    webpack: {
      webpackConfig: './webpack.config.js',
      includeModules: true,
    },
  },
  plugins: [
    'serverless-webpack',
    'serverless-offline',
  ],
  package: { individually: true },
  useDotenv: true,
  provider: {
    name: 'aws',
    runtime: 'nodejs14.x',
    apiGateway: {
      minimumCompressionSize: 1024,
      shouldStartNameWithService: true,
    },
    iam: {
      role: {
        statements: [
          {
            Effect: 'Allow',
            Action: [
              'lambda:InvokeFunction',
              'lambda:InvokeAsync',
            ],
            Resource: [
              envOrDefault('ALEXA_LAMBDA', DEFAULT_ALEXA_LAMBDA),
            ],
          },
        ]
      }
    },
    environment: {
      GIT_HASH: envOrDefault('GIT_HASH', 'no-hash'),
      GIT_BRANCH: envOrDefault('GIT_BRANCH', 'no-branch'),
      GIT_TIME: envOrDefault('GIT_TIME', '1970-01-01T00:00:00Z'),
      STAGE: envOrDefault('STAGE', argSpaceValOrDefault('--stage', '')),
      REGION: envOrDefault('REGION', argSpaceValOrDefault('--region', '')),
      AWS_NODEJS_CONNECTION_REUSE_ENABLED: '1',
      ALEXA_LAMBDA: envOrDefault('ALEXA_LAMBDA', DEFAULT_ALEXA_LAMBDA),
      ALEXA_LAMBDA_PING: envOrDefault('ALEXA_LAMBDA_PING', "true"),
      ALEXA_APPLICATION_ID: envOrDefault('ALEXA_APPLICATION_ID', DEFAULT_ALEXA_APPLICATION_ID),
    },
    lambdaHashingVersion: '20201221',
  },
  // import the function via paths
  functions: { ...proxy },
};

module.exports = serverlessConfiguration;
