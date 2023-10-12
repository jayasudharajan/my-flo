const config = require('../src/config');

module.exports = Object.assign(
	{},
	config,
	{
		env: 'dev', 
		elasticsearch: {
			host: 'http://localhost:9200'
		},
		dynamo: { 
			apiVersion: '2012-08-10',
			region: 'us-west-2',
			accessKeyId: 'foo',
			secretAccessKey: 'bar',
			endpoint: 'http://localhost:8008'
		}
	}
);