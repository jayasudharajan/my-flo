import DeviceDataController from "./controller/DeviceDataController";
import { APIGatewayProxyHandler } from "aws-lambda";
import S3Client from "./s3/S3Client";
import { DynamoDB } from "aws-sdk";
import DynamoDbClient from "./dynamo/DynamoDbClient";
import config from "./config/config";
import DynamoDbService from "./dynamo/DynamoDbService";
import AuthorizationService from "./authorization/AuthorizationService";

// Create services
const s3Client: S3Client = new S3Client();
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dynamoDbService = new DynamoDbService(dynamoDbClient);
const authorizationService = new AuthorizationService();

// Create controllers
const controller: DeviceDataController = new DeviceDataController(s3Client, dynamoDbService, authorizationService);

// Endpoints
export const postTelemetryData: APIGatewayProxyHandler = controller.postTelemetryData;
export const postLogsData: APIGatewayProxyHandler = controller.postLogsData;
export const headFile: APIGatewayProxyHandler = controller.headFile;