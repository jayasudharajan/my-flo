import InfoService from './InfoService'
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class InfoController {
	constructor(infoService) {
		this.infoService = infoService;
	}

	retrieveAllUsers({ query: { size, page }, body: { filter, query, sort } }) {
		return this.infoService.users.retrieveAll({ size, page, filter, query, sort });
	}

	retrieveAllGroupUsers({ params: { group_id }, query: { size, page }, body: { filter, query, sort } }) {
		return this.infoService.users.retrieveAll({
			size,
			page,
			query,
			filter: {
				...filter,
				'account.group_id': group_id
			},
			sort
		});
	}

	retrieveUserByUserId({ params: { user_id } }) {
		return this.infoService.users.retrieveByUserId(user_id);
	}

	retrieveGroupUserByUserId({ params: { group_id, user_id } }) {
		return this.infoService.users.retrieveAll({
			filter: {
				id: user_id,
				'account.group_id': group_id
			}
		});
	}

	retrieveAllICDs({ query: { size, page }, body: { filter, query, sort } }) {
		return this.infoService.icds.retrieveAll({ size, page, filter, query, sort });
	}

	retrieveAllICDsWithScroll({ query: { scroll_ttl = '10s', size }, body: { filter, query, sort } }) {
		return this.infoService.icds.retrieveAllWithScroll({ size, filter, query, sort, scrollTTL: scroll_ttl });
	}

	scrollAllICDs({ query: { scroll_ttl }, params: { scroll_id } }) {
		return this.infoService.icds.scroll(scroll_id, scroll_ttl);
	}

	retrieveAllGroupICDs({ params: { group_id }, query: { size, page }, body: { filter, query, sort } }) {
		return this.infoService.icds.retrieveAll({
			size,
			page,
			query,
			filter: {
				...filter,
				'account.group_id': group_id
			},
			sort
		});
	}

	retrieveICDByICDId({ params: { icd_id } }) {
		return this.infoService.icds.retrieveByICDId(icd_id);
	}

	retrieveGroupICDByICDId({ params: { group_id, icd_id } }) {
		return this.infoService.icds.retrieveAll({
			filter: {
				id: icd_id,
				'account.group_id': group_id
			}
		});
	}

	aggregateICDsByOnboardingEvent({ query: { start, end }, body: { filter, query, sort } }) {
		return this.infoService.icds.aggregateByOnboardingEvent({ startDate: start && parseInt(start), endDate: end && parseInt(end) }, { filter, query, sort });
	}

	retrieveDevicesLeakStatus({ body: { begin, end, leak_status, subscription_status }, query: { size, page } }) {
		return this.infoService.retrieveDevicesLeakStatus(begin, end, leak_status || undefined, subscription_status || undefined, size == 0 ? 0 : (parseInt(size) || undefined), parseInt(page) || undefined);
	}

	retrieveLeakStatusCounts({ body: { begin, end } }) {
		return this.infoService.retrieveLeakStatusCounts(begin, end);
	}
}

export default new DIFactory(new ControllerWrapper(InfoController), [InfoService]);