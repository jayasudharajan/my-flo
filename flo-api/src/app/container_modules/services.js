import _ from 'lodash';
import { ContainerModule } from 'inversify';

const serviceDirs = [
  'legacy-auth',
  'oauth2',
  'authorization',
  'multifactor-authentication',
  'account-v1_5',
  'authentication',
  'client',
  'location-v1_5',
  'system-user',
  'user-account',
  'alerts',
  'info',
  'flo-detect',
  'device-anomaly',
  'push-notification-token',
  'logout',
  'device-system-mode',
  // **** Need to have routes refactored ****
  'task-scheduler',
  'directives',
  'stock-icd',
  'onboarding',
  // ****************************************
  'pairing',
  'icd-v1_5',
  'mqtt-cert',
  'firebase-token',
  'ifttt',
  'google-smart-home',
  'access-control',
  'device-vpn',
  'customer-email-subscription',
  'firmware-features',
  'leak-day',
  'away-mode',
  'insurance-letter',
  'alert-feedback',
  'device-state'
];

export default _.uniq(serviceDirs)
  .map(serviceDir =>
    require(`../services/${ serviceDir }/container`).containerModule
  );