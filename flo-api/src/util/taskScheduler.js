import _ from 'lodash';
import axios from 'axios';
import axiosRetry from 'axios-retry';
import moment from 'moment';
import uuid from 'node-uuid';
import config from '../config/config';
import PendingScheduledTaskTable from '../app/models/PendingScheduledTaskTable';

const pendingScheduledTask = new PendingScheduledTaskTable();
const httpClient = axios.create();
axiosRetry(httpClient, {
	retryCount: 3,
	retryCondition: (error) => (!error.response || (error.response.status >= 500 && error.response.status <= 599)),
	retryDelay: (retryCount) => retryCount * 1000
});

export function scheduleTask(schedulerMessage, logData) {
	const metadata = logData || {};

	return httpClient.request({
		method: 'POST',
		url: `${config.taskSchedulerUrl}/tasks`,
		headers: {
			'Content-Type': 'application/json'
		},
		data: {
			id: schedulerMessage.schedule.id,
			source: 'flo-api',
			schedule: {
				type: 'fixedDate',
				config: {
					target: schedulerMessage.schedule.target
				}
			},
			transport: {
				type: 'kafka',
				payload: {
					topic: schedulerMessage.destination_topic,
					message: schedulerMessage.task_data
				}
			}
		}
	}).then(() => 
		logTaskStatus(schedulerMessage.schedule.id, 'sent', {
			data: schedulerMessage,
			...metadata
		})
	);
}

export function cancelScheduledTask(task_id, logData) {
	const metadata = logData || {};
	return Promise.all([
		httpClient.request({
			method: 'POST',
			url: `${config.taskSchedulerUrl}/tasks/${task_id}/cancel`,
		}),
		logTaskStatus(task_id, 'cancel', {
			...metadata,
			data: {
				task_id,
				action: 'cancel'
			}
		})
	]);
}

export function createSchedulerMessage(destination_topic, task_data, targetDate, taskId = uuid.v4()) {
	return {
		destination_topic,
		task_data,
		schedule: {
			id: taskId,
			target: moment(targetDate).utc().toISOString(),
			expression: moment(targetDate).format('ss mm HH DD MM ? YYYY'), // deprecated
			timezone: 'Etc/UTC' // deprecated
		}
	};
}

export function cancelPendingTasksByIcdId(icd_id, taskType) {
	return pendingScheduledTask.retrieveByIcdId({ icd_id })
		.then(({ Items }) => {
			if (Items && Items.length) {
				return Promise.all(
					Items
						.filter(pendingTask => !taskType || pendingTask.task_type === taskType) 
						.map(pendingTask => 
							cancelScheduledTask(pendingTask.task_id)
						)
				);
			}
		});
}

export function logTaskStatus(task_id, status, logData) {
	const metadata = logData || {};
	const params = {
		...metadata,
		task_id,
		status
	};

	switch (status) {
		case 'sent': 
			return pendingScheduledTask.create(params);
		case 'cancel':
			return pendingScheduledTask.remove({ task_id });
		default: 
			// Do nothing
			break;
	}
	
	return Promise.resolve();
}
