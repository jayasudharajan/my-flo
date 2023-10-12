import UserRegistrationRouter from '../services/user-registration/routes';
import userRegistrationContainer from '../services/user-registration/container';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
	const container = containerUtils.mergeContainers(appContainer, userRegistrationContainer);
	
    app.use('/api/v1/userregistration', container.get(UserRegistrationRouter).router);
}