import SubResourceProvider from './SubResourceProvider';

export default class IFTTTProvider extends SubResourceProvider {
  constructor() {
    super('IFTTT');
  }

  retrieveByToken(params, { user_id }) {
    return Promise.resolve(this.formatSubResource(user_id));
  }
}
 