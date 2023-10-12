import ResourceStrategy from './ResourceStrategy';

class GoogleSmartHomeResourceStrategy extends ResourceStrategy {
  constructor() {
    super('GoogleSmartHome', 'user_id', {
      retrieveByUserId(userId) {
        return Promise.resolve({ Items: [{ user_id: userId, roles: [] }] });
      }
    });
  }
}

export default GoogleSmartHomeResourceStrategy;