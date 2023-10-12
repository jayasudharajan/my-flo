import { scheduleTask, createSchedulerMessage, cancelPendingTasksByIcdId } from '../../../util/taskScheduler';
import DIFactory from  '../../../util/DIFactory';

class TaskSchedulerService {
	constructor() {}

	// Schedules a one-time task at a specific date/time. 
	schedule(targetDate, destinationTopic, taskData, taskId, metadata) {
		const msg = createSchedulerMessage(destinationTopic, taskData, targetDate, taskId)
		return scheduleTask(msg, metadata);
	}

	cancel(taskId, metadata = {}) {
		return cancelScheduledTask(taskId, metadata);
	}

	cancelTasksByIcdId(icdId, taskType) {
		return cancelPendingTasksByIcdId(icdId, taskType);
	}
}

export default new DIFactory(TaskSchedulerService, []);