import config from './config/config';
import AppServerFactory from './AppServerFactory'
import container from './container';

const appServer = new AppServerFactory(config, container, { verbose: true });

export default appServer.instance();