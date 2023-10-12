const AWS = require('aws-sdk');
const uuid = require('uuid');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const config = require('../../../../dist/config/config');
const NotificationTokenSchema = require('../../../../dist/app/models/schemas/notificationTokenSchema');
const NotificationTokenTable = require('../../../../dist/app/services/notification-token/NotificationTokenTable');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const inversify = require('inversify');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const reflect = require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
	config.aws.dynamodb.endpoint,
	[ NotificationTokenSchema ],
	config.aws.dynamodb.prefix
);

describeWithMixins('NotificationTokenTable', [ dynamoDbTestMixin ], () => {
	// Declare bindings
	const container = new inversify.Container();
	container.bind(NotificationTokenTable).to(NotificationTokenTable);
	container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

	// Resolve dependencies
	const notificationTokenTable = container.get(NotificationTokenTable);

	describe('#addToken', () => {
		it('should add new iOS token', done => {
			const user_id = uuid.v4();
			const token = uuid.v4();

			notificationTokenTable.addToken(user_id, token, 'ios')
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item.ios_tokens)
				.should.eventually.deep.equal([token])
				.notify(done);
		});

		it('should add new Android token', done => {
			const user_id = uuid.v4();
			const token = uuid.v4();

			notificationTokenTable.addToken(user_id, token, 'android')
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item.android_tokens)
				.should.eventually.deep.equal([token])
				.notify(done);
		});

		it('should add an additional iOS token', done => {
			const user_id = uuid.v4();
			const token1 = uuid.v4();
			const token2 = uuid.v4();
			const token3 = uuid.v4();

			notificationTokenTable.create({ user_id, ios_tokens: [token1], android_tokens: [token3] })
				.then(() => notificationTokenTable.addToken(user_id, token2, 'ios'))
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item)
				.should.eventually.deep.equal({
				user_id,
				ios_tokens: [token1, token2],
				android_tokens: [token3]
			})
				.notify(done);
		});

		it('should add an additional android token', done => {
			const user_id = uuid.v4();
			const token1 = uuid.v4();
			const token2 = uuid.v4();
			const token3 = uuid.v4();

			notificationTokenTable.create({ user_id, ios_tokens: [token1], android_tokens: [token2] })
				.then(() => notificationTokenTable.addToken(user_id, token3, 'android'))
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item)
				.should.eventually.deep.equal({
				user_id,
				ios_tokens: [token1],
				android_tokens: [token2, token3]
			})
				.notify(done);
		});

		it('should fail to add a non-iOS/Android token', done => {
			const user_id = uuid.v4();
			const token = uuid.v4();

			notificationTokenTable.addToken(user_id, token, 'windows_phone')
				.should.eventually.be.rejectedWith(ValidationException)
				.notify(done);
		});

	});

	describe('#removeToken', () => {
		it('should remove an iOS token', done => {
			const user_id = uuid.v4();
			const token1 = uuid.v4();
			const token2 = uuid.v4();
			const token3 = uuid.v4();

			notificationTokenTable.create({ user_id, ios_tokens: [token1, token2], android_tokens: [token3] })
				.then(() => notificationTokenTable.removeToken(user_id, token1))
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item)
				.should.eventually.deep.equal({
				user_id,
				ios_tokens: [token2],
				android_tokens: [token3]
			})
				.notify(done);
		});

		it('should remove an Android token', done => {
			const user_id = uuid.v4();
			const token1 = uuid.v4();
			const token2 = uuid.v4();
			const token3 = uuid.v4();

			notificationTokenTable.create({ user_id, ios_tokens: [token1, token2], android_tokens: [token3] })
				.then(() => notificationTokenTable.removeToken(user_id, token3))
				.then(() => notificationTokenTable.retrieve({ user_id }))
				.then(({ Item }) => Item)
				.should.eventually.deep.equal({
				user_id,
				ios_tokens: [token1, token2],
				android_tokens: []
			})
				.notify(done);
		});
	});
});