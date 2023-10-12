/**
 * Stubbed webhooks.
 */
import _ from 'lodash';
import { deliveryMedium, deliveryStatus, sendGridEvent, convertEmailStatus } from '../../util/enums';
import uuid from 'node-uuid';


import ICDAlarmIncidentRegistryLogTable from '../models/ICDAlarmIncidentRegistryLogTable';
import EmailDeliveryLogTable from '../models/EmailDeliveryLogTable';
import PushNotificationDeliveryLogTable from '../models/PushNotificationDeliveryLogTable';
import SMSDeliveryLogTable from '../models/SMSDeliveryLogTable';
import ICDAlarmIncidentRegistryTable from '../models/ICDAlarmIncidentRegistryTable';

let ICDAlarmIncidentRegistry = new ICDAlarmIncidentRegistryTable();
let ICDAlarmIncidentRegistryLog = new ICDAlarmIncidentRegistryLogTable();
let emailDeliveryLog = new EmailDeliveryLogTable();
let pushNotificationDeliveryLog = new PushNotificationDeliveryLogTable();
let SMSDeliveryLog = new SMSDeliveryLogTable();

export function emailServiceWebhook(req, res, next) {

 const {icd_alarm_incident_registry_id, user_id} = req.params;

   ICDAlarmIncidentRegistry.retrieve({ id: icd_alarm_incident_registry_id })
   .then(({ Item }) => {

       if (!Item) {
           return next({ status: 404, message: "ICDAlarmIncidentRegistry not found."  });
       }
       const email =  2 ;
       const statusSent = 3;

       const icdAlarmIncidentRegistry = {
            created_at: new Date().toISOString(),
            delivery_medium: email,
            icd_alarm_incident_registry_id,
            id: uuid.v4(),
            receipt_id: req.body.receipt_id,
            status : statusSent,
            user_id
        };

      return  ICDAlarmIncidentRegistryLog.create(icdAlarmIncidentRegistry)
    })
    .then(result=>{

       if(!result){
           return next("ICDAlarmIncidentRegistryLog could not be created.");
       }

       res.json(result)

   })
   .catch(err => next(err))
}

export function logEmailStatus(req, res, next) {

  // TODO: account for and process multiple items in body.
  // [{"swu_template_id":"tem_WrqE2RxjNynp6vyKmMZztG","ip":"167.89.17.173","response":"250 2.0.0 OK 1467771075 d21si1363495ioe.15 - gsmtp ","sg_event_id":"Gga2S5eOQ3-te9SzRcx6SQ","sg_message_id":"WicTfd5oQ-KQGFuiDfgyhw.filter0537p1mdw1.14336.577C68BD8.0","swu_template_version_id":"ver_AuZYZ86XQQ7VhwnJEeVE9f","tls":1,"event":"delivered","email":"steve@flotechnologies.com","timestamp":1467771075,"smtp-id":"<WicTfd5oQ-KQGFuiDfgyhw@ismtpd0002p1iad1.sendgrid.net>","receipt_id":"log_be1382313cfdd38c2e49dbcc551c9ee1"}]
  let statusItems = req.body;

  //res.json(req.body[0]);

  // Create an array of promises.
  let promises = [];

  for(let data of statusItems) {
    // If it is an event we want to capture, log it.
    // TODO: test events.

    // req.log.info(data.event);
    // req.log.info(sendGridEvent[data.event]);
    // req.log.info(deliveryStatus[sendGridEvent[data.event]]);
    // req.log.info(convertEmailStatus[data.event]);

    if(deliveryStatus[sendGridEvent[data.event]]) {
      promises.push(ICDAlarmIncidentRegistryLog.logStatus(data));
      // TODO: re-add EmailDeliveryLog.
    }
  }

  Promise.all(promises)
    .then(result => {
      // TODO: do we need to do anything with the result?
      res.json({ message: "Email status updated." }); // ALL OK!
    })
    .catch(err => {
      next(err);
    });

  /**
  // Example of what gets returned from SendWithUs.
  [{
    "swu_template_id": "tem_hDf3VtdT",
    "response": "250 2.0.0 OK 1444932357 g7si74876igq.93 - gsmtp ",
    "sg_event_id": "BEfpqsQ1QAmNJ2iDX814rg",
    "sg_message_id": "sSk9ILQ.filterdw1.112.47.0",
    "swu_template_version_id": "ver_YaPiU9j",
    "event": "delivered",
    "email": "us@sendwithus.com",
    "timestamp": 1444932357,
    "smtp-id": "<9ogM8LQ@ad1.sendgrid.net>",
    "receipt_id": "log_b3463626f2c17"
  }]

  DONE
  // add message_tracking_id as GSI to ICDAlarmIncidentRegistryLog
  DONE
  // delete and recreate ICDAlarmIncidentRegistryLog table
  DONE
  // delete and recreate ICDAlarmIncidentRegistryLog table on DEV
  DONE
  // create function to query ICDAlarmIncidentRegistryLog by message_tracking_id
  DONE
  // parse request body for values
  DONE
  // create enums as appropriate for numeric delivery values
  DONE
  // retrieve - ICDAlarmIncidentRegistryLog based on receipt_id
  DONE
  // create new - ICDAlarmIncidentRegistryLog based cloned from prior entry
  DONE
  // revise EmailDeliveryLog Index
  DONE
  // delete and recreate EmailDeliveryLog table
  DONE
  // delete and recreate EmailDeliveryLog table on DEV
  DONE
  // retrieve new EmailDeliveryLog based on receipt_id
  DONE
  // create new - EmailDeliveryLog cloned from prior entry
  */

  // let receipt_id = data.receipt_id;


  // ICDAlarmIncidentRegistryLog.retrieveByReceiptId({ receipt_id })
  //   .then(incidentLog => {

  //     if(!_.isEmpty(incidentLog.Items)) {

  //       // Sort for most recent entry if multiple.
  //       let items = [];
  //       if(incidentLog.Items.length > 1) {
  //         items = _.orderBy(incidentLog.Items, ['created_at'], ['desc']);
  //       } else {
  //         items = incidentLog.Items;
  //       }

  //       // Clone and clean most recent log item.
  //       let logItem = _.clone(items[0]);
  //       delete logItem.unique_id;
  //       delete logItem.created_at;

  //       // Modify status.
  //       let newStatus = deliveryStatus[data.event];
  //       logItem.status = newStatus;
  //       logItem.delivery_medium_status = ICDAlarmIncidentRegistryLog.createRange(deliveryMedium.email, newStatus);

  //       return ICDAlarmIncidentRegistryLog.create(logItem);

  //     } else {
  //       // TODO: return rejected promise.
  //       return new Promise((resolve, reject) => { reject({ statusCode: 404, message: "No ICDAlarmIncidentRegistryLog found." }) });
  //     }

  //   })
  //   .then(incidentLogCreate => {

  //     if(!_.isEmpty(incidentLogCreate)) {
  //       return emailDeliveryLog.retrieveByReceiptId({ receipt_id });
  //     } else {
  //       return new Promise((resolve, reject) => { reject({ status: 404, message: "Unable to create ICDAlarmIncidentRegistryLog." }) });
  //     }

  //   })
  //   .then(emailDeliveryLogs => {

  //     console.log(emailDeliveryLogs);

  //     // review what comes back if empty.
  //     if(!_.isEmpty(emailDeliveryLogs)) {

  //       // Sort for most recent entry if multiple.
  //       let items = [];
  //       if(emailDeliveryLogs.Items.length > 1) {
  //         items = _.orderBy(emailDeliveryLogs.Items, ['created_at'], ['desc']);
  //       } else {
  //         items = emailDeliveryLogs.Items;
  //       }

  //       // Clone and clean most recent log item.
  //       let emailLogItem = _.clone(items[0]);
  //       delete emailLogItem.id;

  //       // Modify status.
  //       let newStatus = deliveryStatus[data.event];
  //       emailLogItem.status = newStatus;

  //       return emailDeliveryLog.create(emailLogItem);

  //     } else {
  //       return new Promise((resolve, reject) => { reject({ status: 404, message: "EmailDeliveryLog item not found." }) });
  //     }

  //   })
  //   .then(emailDeliveryLogCreate => {

  //     if(!_.isEmpty(emailDeliveryLogCreate)) {
  //       res.json({ message: "Email status updated." }); // ALL OK!
  //     } else {
  //       return new Promise((resolve, reject) => { reject({ status: 404, message: "Unable to create EmailDeliveryLog." }) });
  //     }

    // })
    // .catch(err => {
    //   next(err);
    // });

}

export function logSmsStatus(req, res) {

  let data = req.body;

  // Example of what gets returned from Twilio.
  //SmsSid=SM04363cdd65ee4cb2b17e3bbf56ed084d&SmsStatus=sent&MessageStatus=sent&To=%2B5491158898021&MessageSid=SM04363cdd65ee4cb2b17e3bbf56ed084d&AccountSid=ACaa2812ccce4051bf11a25a73ba37ec0b&From=%2B15594680975&ApiVersion=2010-04-01

  // TODO: validation.

  let receipt_id = data.MessageSid;


  ICDAlarmIncidentRegistryLog.retrieveByReceiptId({ receipt_id })
    .then(incidentLog => {

      if(!_.isEmpty(incidentLog.Items)) {

        // Sort for most recent entry if multiple.
        let items = [];
        if(incidentLog.Items.length > 1) {
          items = _.orderBy(incidentLog.Items, ['created_at'], ['desc']);
        } else {
          items = incidentLog.Items;
        }

        // Clone and clean most recent log item.
        let logItem = _.clone(items[0]);
        delete logItem.unique_id;
        delete logItem.created_at;

        // Modify status.
        let newStatus = deliveryStatus[data.event];
        logItem.status = newStatus;
        logItem.delivery_medium_status = ICDAlarmIncidentRegistryLog.createRange(deliveryMedium.email, newStatus);

        return ICDAlarmIncidentRegistryLog.create(logItem);

      } else {
        return new Promise((resolve, reject) => { reject({ statusCode: 404, message: "No ICDAlarmIncidentRegistryLog found." }) });
      }

    })
    .then(incidentLogCreate => {

      if(!_.isEmpty(incidentLogCreate)) {
        return smsDeliveryLog.retrieveByReceiptId({ receipt_id });
      } else {
        return new Promise((resolve, reject) => { reject({ status: 404, message: "Unable to create ICDAlarmIncidentRegistryLog." }) });
      }

    })
    .then(smsDeliveryLogs => {
      // review what comes back if empty.
      if(!_.isEmpty(smsDeliveryLogs)) {

        // Sort for most recent entry if multiple.
        let items = [];
        if(smsDeliveryLogs.Items.length > 1) {
          items = _.orderBy(smsDeliveryLogs.Items, ['created_at'], ['desc']);
        } else {
          items = smsDeliveryLogs.Items;
        }

        // Clone and clean most recent log item.
        let smsLogItem = _.clone(items[0]);
        delete smsLogItem.id;

        // Modify status.
        let newStatus = deliveryStatus[data.event];
        smsLogItem.status = newStatus;

        return smsDeliveryLog.create(smsLogItem);

      } else {
        return new Promise((resolve, reject) => { reject({ status: 404, message: "SMSDeliveryLog item not found." }) });
      }

    })
    .then(smsDeliveryLogCreate => {

      if(!_.isEmpty(smsDeliveryLogCreate)) {
        res.json({ message: "Email status updated." }); // ALL OK!
      } else {
        return new Promise((resolve, reject) => { reject({ status: 404, message: "Unable to create SMSDeliveryLog." }) });
      }

    })
    .catch(err => {
      next(err);
    });

}

export function pushStatus(req, res) {
  res.json({ message: "Yo no tengo nada." });
}


