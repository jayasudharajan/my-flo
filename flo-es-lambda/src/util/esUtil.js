
exports.insertArrayItem = insertArrayItem;
exports.replaceArrayItem = replaceArrayItem;
exports.removeArrayItem = removeArrayItem;
exports.mergeArrayItem = mergeArrayItem;


function insertArrayItem(prop, param) {
	const inline = 
		`if (ctx._source.containsKey("${prop}")) { ctx._source.${prop}.add(params.${prop}); }` + 
		`else { ctx._source.${prop} = [params.${prop}]; }`;

	return {
		inline,
		lang: 'painless',
		params: {
			[prop]: param
		}
	};
}

function replaceArrayItem(prop, param, on) {
	const inline = 
		`if (ctx._source.containsKey("${prop}")) {` +
			`ctx._source.${prop}.removeIf(item -> item["${on}"] == params.${prop}["${on}"]);` +
			`ctx._source.${prop}.add(params.${prop});` +
		`} else { ctx._source.${prop} = [params.${prop}]; }`;

	return {
		inline,
		lang: 'painless',
		params: {
			[prop]: param
		}
	};
}

function removeArrayItem(prop, param, on) {
	const inline = 
		`if (ctx._source.containsKey("${prop}"))` + 
		`{ ctx._source.${prop}.removeIf(item -> item["${on}"] == params.${prop}["${on}"]); }`;

	return {
		inline,
		lang: 'painless',
		params: {
			[prop]: param
		}
	};
}

function mergeArrayItem(prop, param, on) {
	const inline = 
		`if (ctx._source.containsKey("${prop}")) {` +
			`def data = ctx._source.${prop}.find(item -> item["${on}"] == params.${prop}["${on}"]);` +
			`if (data != null) {` +
				`int i = ctx._source.${prop}.indexOf(data);` +
				`Map dataMap = (Map)data;` +
				`dataMap.putAll((Map)params.${prop});` +
				`ctx._source.${prop}[i] = dataMap;` +
			`} else { ctx._source.${prop}.add(params.${prop}); }` +
		`} else { ctx._source.${prop} = [params.${prop}]; }`;

		return {
			inline,
			lang: 'painless',
			params: {
				[prop]: param
			}
		};
}