import DIFactory from  '../../../util/DIFactory';
import DirectiveResponseTable from './DirectiveResponseTable';
import ICDService from '../icd/ICDService'

class DirectiveResponseService {

	constructor(directiveResponseTable, icdService) {
		this.directiveResponseTable = directiveResponseTable;
		this.icdService = icdService;
	}

	logDirectiveResponse(deviceId, data) {
		return this.icdService
			.lookupByDeviceId(deviceId)
			.then(({ id: icd_id }) => this.directiveResponseTable.createLatest({ ...data, icd_id }))
	}
}

export default new DIFactory(DirectiveResponseService, [ DirectiveResponseTable, ICDService ]);