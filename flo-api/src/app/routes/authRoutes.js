import routes from '../services/auth/routes';

export default (app) => {

    app.use('/api/v1/auth', routes);
}