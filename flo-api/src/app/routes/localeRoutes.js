import LocaleRouter from '../services/locale/routes';
import localeContainer from '../services/locale/container';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
	const container = containerUtils.mergeContainers(appContainer, localeContainer);
	
    app.use('/api/v1/locales', container.get(LocaleRouter).router);
}