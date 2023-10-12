import _ from 'lodash';
import { clearNotification, ALARM_IDS, SYTEM_MODES } from '../../util/alarmUtils';
import ICDAlarmNotificationDeliveryRuleTable from '../models/ICDAlarmNotificationDeliveryRuleTable';
import UserAlarmNotificationDeliveryRuleTable from '../models/UserAlarmNotificationDeliveryRuleTable';
import { 
	getMostSevereMostRecent, 
	getPendingAlerts, 
	getClearedAlerts, 
	getAlertsBySeverity, 
	getAlertsByAlarmIdSystemMode, 
	getAlertsBySeverityAndAlarmIdSystemMode, 
	getFullActivityLog, 
	getAnalytics, 
	getAlertsByLocation, 
	getDailyLeakTestResult, 
	getDailyAlertCount 
} from '../services/alerts/alerts';

const ICDAlarmNotificationDeliveryRule = new ICDAlarmNotificationDeliveryRuleTable();
const UserAlarmNotificationDeliveryRule = new UserAlarmNotificationDeliveryRuleTable();

const MAX_PAGE_SIZE = 15;

export function retrieveDeliveryRules(req, res, next) {
	const { user_id } = req.params;
	const defaultDeliveryRulePromise = Promise.all(
		_.map(
			ALARM_IDS, 
			alarm_id => ICDAlarmNotificationDeliveryRule.retrieveByAlarmId({ alarm_id })
		)
	)
	.then(results => _.flatMap(results, ({ Items }) => Items));
	const userDeliveryRulePromise = UserAlarmNotificationDeliveryRule.retrieveByUserId({ user_id })
		.then(({ Items }) => 
			_.chain(Items)
				.groupBy(({ location_id }) => location_id)
				.map((delivery_rules, location_id) => ({ location_id, delivery_rules }))
				.value()
		);

	Promise.all([defaultDeliveryRulePromise, userDeliveryRulePromise])
		.then(([default_delivery_rules, override_delivery_rules]) => {
			res.json({
				default_delivery_rules,
				override_delivery_rules
			})
		})
		.catch(next);
}

export function retrievePendingNotifications(req, res, next) {
	const { 
		params: { icd_id },
		query: { size, page },
		body: { filter }
	} = req;

	getPendingAlerts(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrieveClearedNotifications(req, res, next) {
	const { 
		params: { icd_id },
		query: { size, page },
		body: { filter }
	} = req;

	getClearedAlerts(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrievePendingSeverityBySeverity(req, res, next) {
	const { 
		params: { icd_id }, 
		query: { size, page },
		body: { filter } 
	} = req;

	getAlertsBySeverity(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrievePendingNotificationsByAlarmIdSystemMode(req, res, next) {
	const { 
		params: { icd_id }, 
		query: { size, page },
		body: { filter } 
	} = req;

	getAlertsByAlarmIdSystemMode(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));	
}

export function retrievePendingNotificationsBySeverityAndAlarmIdSystemMode(req, res, next) {
	const { 
		params: { icd_id }, 
		query: { size, page },
		body: { filter } 
	} = req;

	getAlertsBySeverityAndAlarmIdSystemMode(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));	
}

export function retrieveFullActivityLog(req, res, next) {
	const {
		params: { icd_id },
		query: { size, page },
		body: { filter }
	} = req;

	getFullActivityLog(icd_id, { size: parseInt(size), page: parseInt(page), filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrieveGroupFullActivityLog(req, res, next) {
	const {
		params: { group_id, icd_id },
		query: { size, page },
		body: { filter = {} }
	} = req;

	getFullActivityLog(
		icd_id, 
		{ 
			size: parseInt(size), 
			page: parseInt(page),
			filter: {
				...filter,
				'account.group_id': group_id
			}
		}
	)
	.then(result => res.json(result))
	.catch(handleError(req, res, next));
}

export function clearNotifications(req, res, next) {
	const { icd_id, user_id } = req.params;
	const { data: alarmIdSystemModes } = req.body;

	Promise.all(
		(alarmIdSystemModes || []).map(
			({ alarm_id, system_mode }) => clearNotification(user_id, icd_id, alarm_id, system_mode)
		)
	)
	.then(() => res.json(alarmIdSystemModes))
	.catch(err => next(err));
}

export function retrieveAnalytics(req, res, next) {
	const {
		query: { size, page },
		body: { filter }
	} = req;

	getAnalytics({ size, page, filter })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrievePendingGroupAlertsByLocation(req, res, next) {
	const {
		params: { group_id },
		body: { filter = {} }
	} = req;

	getAlertsByLocation({ ...filter, 'account.group_id': group_id })
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrieveDailyLeakTestResult(req, res, next) {
	const { body: { begin, end } } = req;

	getDailyLeakTestResult(begin, end)
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

export function retrieveDailyAlertCountByGroupId(req, res, next) {
	const { params: { group_id }, body: { filter = {} }, query: { tz } } = req;

	getDailyAlertCount({ ...filter, 'account.group_id': group_id }, tz)
		.then(result => res.json(result))
		.catch(handleError(req, res, next));
}

function handleError(req, res, next) {

	return err => {

		if (err.status == 400) {
			req.log.error({ err });
			next({ status: 400, message: 'Invalid query.' });
		} else if (err.status) {
			req.log.error({ err });
			next({ status: 500 });
		} else {
			next(err);
		}
	};
}