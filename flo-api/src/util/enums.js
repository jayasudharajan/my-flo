/**
 *
 *  For now see: https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Workflow
 * 
 */

export const deliveryMedium = {
  FILTERED: 1,
  EMAIL: 2,
  PUSH: 3,
  SMS: 4
};

export const deliveryStatus = {
  NONE: 1,
  TRIGGERED: 2,  
  SENT: 3,  
  DELIVERED: 4,  
  FAILED: 5,  
  OPENED: 6,  
  BOUNCE: 7,  
  DROPPED: 8
};

export const deliveryFilterStatus = {
  RESOLVED: 1,
  IGNORED: 2,
  UNRESOLVED: 3
}

export const sendGridEvent = {
  delivered: 'DELIVERED',
  bounce: 'BOUNCE',
  open: 'OPENED',
  dropped: 'DROPPED'
};

export function convertEmailStatus(eventName) {
  return deliveryStatus[sendGridEvent[eventName]];
}
