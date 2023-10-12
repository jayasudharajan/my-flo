const getTableName = require('./util/util').getTableName;

module.exports = function () {
	var handlers = {};

	this.subscribe = function (_tableName, events, handler) {
		const tableName = getTableName(_tableName);

		if (!handlers[tableName]) {
			handlers[tableName] = {};
		}

		events.forEach(event => {
			if (!handlers[tableName][event]) {
				handlers[tableName][event] = [];
			}

			handlers[tableName][event].push(handler);
		});
	};

	this.publish = function (tableName, event, item) {
		const promises = (handlers[tableName][event] || [])
			.map(handler => handler(item));

		return Promise.all(promises);
	};
}