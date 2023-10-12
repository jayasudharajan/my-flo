import PasswordlessRouter from '../services/passwordless/routes';
import PasswordlessContainer from '../services/passwordless/container';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
	const container = containerUtils.mergeContainers(appContainer, PasswordlessContainer);
	
    app.use('/api/v1/passwordless', container.get(PasswordlessRouter).router);
}