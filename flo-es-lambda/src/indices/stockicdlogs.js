const esClient = require('../db/esClient');
const doctypes = require('../util/doctypes');
const util = require('../util/util');
const EVENTS = util.EVENTS;

function indexStockICDLog(body) {
	return esClient.index({
		index: 'stockicdlogs',
		type: 'stockicdlog',
		body
	});
}

module.exports = pubsub => {

	pubsub.subscribe('StockICD', [EVENTS.INSERT], stockICD => {
		const doc = doctypes.createStockICDLog(stockICD, EVENTS.INSERT);

		return indexStockICDLog(doc);
	});

	pubsub.subscribe('StockICD', [EVENTS.MODIFY], stockICD => {
		const doc = doctypes.createStockICDLog(stockICD, EVENTS.MODIFY);

		return indexStockICDLog(doc);
	});

	pubsub.subscribe('StockICD', [EVENTS.REMOVE], stockICD => {
		const doc = doctypes.createStockICDLog(stockICD, EVENTS.REMOVE);

		return indexStockICDLog(doc);
	});
}