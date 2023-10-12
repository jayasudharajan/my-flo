import AlarmRouter from '../services/alarm/routes';
import alarmContainer from '../services/alarm/container';
import containerUtils from '../../util/containerUtil';

export default (app, container) => {
	const routesContainer = containerUtils.mergeContainers(container, alarmContainer);
  	const alarmRouter = routesContainer.get(AlarmRouter);

    app.use('/api/v1/alarms', alarmRouter.router);
}