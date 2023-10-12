import DeviceDataController from "../src/controller/DeviceDataController";
import S3Client from "../src/s3/S3Client";
import { Context, Callback, APIGatewayProxyResult } from "aws-lambda";
import AWS, { DynamoDB } from "aws-sdk";
import config from "../src/config/config";
import DynamoDbClient from "../src/dynamo/DynamoDbClient";
import DynamoDbService from "../src/dynamo/DynamoDbService";
import AuthorizationService from "../src/authorization/AuthorizationService";

AWS.config.update({region: 'us-west-2'});

const event = require('./../../mocked-data/event');
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dynamoDbService = new DynamoDbService(dynamoDbClient);
const authorizationService = new AuthorizationService();

const s3Client: S3Client = new S3Client();
const controller = new DeviceDataController(s3Client, dynamoDbService, authorizationService)

controller.postTelemetryData(event, {} as Context, {} as Callback<APIGatewayProxyResult>)
