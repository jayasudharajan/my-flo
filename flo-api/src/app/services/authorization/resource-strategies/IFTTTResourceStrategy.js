import ResourceStrategy from './ResourceStrategy';

class IFTTTResourceStrategy extends ResourceStrategy {
  constructor() {
    super('IFTTT', 'user_id', {
      retrieveByUserId(userId) {
        return Promise.resolve({ Items: [{ user_id: userId, roles: [] }] });
      }
    });
  }
}

export default IFTTTResourceStrategy;