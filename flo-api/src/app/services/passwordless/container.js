import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import containerUtil from '../../../util/containerUtil';
import userAccountContainer from '../user-account/container';
import oauth2Container from '../oauth2/container';
import authenticationContainer from '../authentication/container';
import authorizationContainer from '../authorization/container';
import PasswordlessService from './PasswordlessService';
import PasswordlessController from './PasswordlessController';
import PasswordlessRouter from './routes';
import PasswordlessConfig from './PasswordlessConfig';
import EmailClient from '../utils/EmailClient';
import EmailClientConfig from '../utils/EmailClientConfig';
import PasswordlessClientTable from './PasswordlessClientTable';

const container = new Container();

container.bind(PasswordlessService).to(PasswordlessService);
container.bind(PasswordlessController).to(PasswordlessController);
container.bind(PasswordlessRouter).to(PasswordlessRouter);
container.bind(PasswordlessClientTable).to(PasswordlessClientTable);
container.bind(PasswordlessConfig).toConstantValue(new PasswordlessConfig(config));
container.bind(EmailClient).toConstantValue(new EmailClient(new EmailClientConfig(config)));
	
export default [
	userAccountContainer,
	oauth2Container,
	authenticationContainer,
	authorizationContainer
].reduce(containerUtil.mergeContainers, container);