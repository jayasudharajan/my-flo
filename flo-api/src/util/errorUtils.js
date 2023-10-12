
export const ERROR_CODE = {
	DYNAMODB_ERROR: 0,
	API_ERROR: 1
};

function mapErrorCode(error) {
	switch (error.code) {
		case 'AccessDeniedException':
		case 'ConditionalCheckFailedException':
		case 'IncompleteSignatureException':
		case 'ItemCollectionSizeLimitExceededException':
		case 'LimitExceededException':
		case 'MissingAuthenticationTokenException':
		case 'ProvisionedThroughputExceededException':
		case 'ResourceInUseException':
		case 'ResourceNotFoundException':
		case 'ThrottlingException':
		case 'UnrecognizedClientException':
		case 'ValidationException':
			return ERROR_CODE.DYNAMODB_ERROR;
		default:
			return ERROR_CODE.API_ERROR;
	}
}

function mapErrorMessage(error) {
	const defaultMessage = 'Something went wrong. Please contact Flo support. Error code: ' + mapErrorCode(error);
	switch (error.status) {
		case 400:
		case 401:
		case 403:
		case 404:
		case 409:
		case 429:
			return error.message || defaultMessage;
		case 500:
		default:
			return defaultMessage;
	}
}

export function normalizeError(error) {
	const status = error.status ? parseInt(error.status) : 500;
	const message = mapErrorMessage({ status, ...error });
	const data = error.data || {};

	return { status, message, ...data };
}