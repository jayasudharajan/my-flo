import DeviceDataController from "../src/controller/DeviceDataController";
import S3Client from "../src/s3/S3Client";
import { Context, Callback, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDB } from "aws-sdk";
import config from "../src/config/config";
import DynamoDbClient from "../src/dynamo/DynamoDbClient";
import DynamoDbService from "../src/dynamo/DynamoDbService";
import AuthorizationService from "../src/authorization/AuthorizationService";

const event = require('./../../mocked-data/event');
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dynamoDbService = new DynamoDbService(dynamoDbClient);
const authorizationService = new AuthorizationService();

const s3Client: S3Client = new S3Client();
const controller = new DeviceDataController(s3Client, dynamoDbService, authorizationService)

event.pathParameters = {
  type: 'telemetry'
}
event.queryStringParameters = {
  signature: 'eed8fcaeb123119258da4d04f412a052350bb91f9a5a7ba1991dfd54c3feccee',
  macAddress: 'f87aef01052e',
  createdAt: '2019-07-29T21:30:41.418968'
}

controller.headFile(event, {} as Context, {} as Callback<APIGatewayProxyResult>)
