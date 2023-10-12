import crypto from 'crypto';

export default class AuthorizationService {
  constructor(
  ) {}

  /**
   * Returns the signature of the content using HMAC sha256
   * @param content 
   */
  public signBlobContent(content: Buffer, key: string): string {
    return crypto.createHmac('sha256', key).update(content).digest('hex');
  }
}