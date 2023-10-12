import { APIGatewayProxyResult } from "aws-lambda";

export default class DeviceDataController {

  public sendSuccessResponse(body: string = "success"): APIGatewayProxyResult {
    return {
      statusCode: 202,
      body: JSON.stringify({
        message: body,
        status: 202
      })
    }
  }

  public sendNotFoundResponse(body: string = "Resource not found"): APIGatewayProxyResult {
    console.warn(`RESPONSE 404 -> ${body}`);
    return {
      statusCode: 404,
      body: JSON.stringify({
        message: body,
        status: 404
      })
    }
  }

  public sendBadRequestResponse(body: string = "Bad request"): APIGatewayProxyResult {
    console.warn(`RESPONSE 400 -> ${body}`);
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: body,
        status: 400
      })
    }
  }

  public sendUnauthorizedResponse(body: string = "Unauthorized"): APIGatewayProxyResult {
    console.warn(`RESPONSE 403 (401) -> ${body}`);
    return {
      statusCode: 403, //should be 401 but FW can't handle 401 properly
      body: JSON.stringify({
        message: body,
        status: 403
      })
    }
  }

  public sendForbiddenResponse(body: string = "Forbidden"): APIGatewayProxyResult {
    console.warn(`RESPONSE 403 (403) -> ${body}`);
    return {
      statusCode: 403,
      body: JSON.stringify({
        message: body,
        status: 403
      })
    }
  }

  /** we are emulating 202 so it doesn't retry & flood the system in this case */
  public sendConflictResponse(body: string = "success"): APIGatewayProxyResult {
    console.warn(`RESPONSE 202 (409) -> ${body}`);
    return {
      statusCode: 202, //should be 409 but FW can't handle it, 
      body: JSON.stringify({
        message: body,
        status: 202
      })
    }
  }
}