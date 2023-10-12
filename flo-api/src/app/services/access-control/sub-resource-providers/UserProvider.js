import SubResourceProvider from './SubResourceProvider';

export default class UserProvider extends SubResourceProvider {
  constructor() {
    super('User');
  }

  retrieveByUserId({ user_id }) {
    return Promise.resolve(this.formatSubResource(user_id));
  }

  retrieveByToken(params, { user_id }) {
    return Promise.resolve(this.formatSubResource(user_id));
  }
}
