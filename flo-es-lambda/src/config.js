module.exports = {
	env: process.env.environment,
	s3: {
		accessKeyId: process.env.S3_ACCESS_KEY_ID,
		secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
		bucketRegion: process.env.S3_BUCKET_REGION,
		bucketName: process.env.S3_BUCKET_NAME,
		keyPathTemplate: process.env.S3_KEY_PATH_TEMPLATE
	},
	elasticsearch: {
		host: process.env.ELASTICSEARCH_HOST
	},
	dynamo: { 
		apiVersion: '2012-08-10',
		encryptionKeyId: process.env.DYNAMODB_ENCRYPTION_KEY_ID
	},
	encryptedTables: {
		UserDetail: [
			'firstname', 
			'lastname', 
			'middlename', 
			'phone_mobile'
		],
		Location: [
			'address',
			'address2',
			'city',
			'country',
			'location_type',
			'postalcode',
			'state',
			'timezone'
		],
		User: [
			'email'
		],
		StockICD: [
			'icd_client_key',
	        'icd_client_cert',
	        'icd_login_token',
	        'icd_websocket_cert',
	        'icd_websocket_cert_der',
	        'icd_websocket_key',
	        'wifi_password',
	        'ssh_private_key'
		]
	}
};