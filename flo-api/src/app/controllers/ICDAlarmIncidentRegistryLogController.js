import _ from 'lodash';
import moment from 'moment';
import ICDAlarmIncidentRegistryLogTable from '../models/ICDAlarmIncidentRegistryLogTable';
let ICDAlarmIncidentRegistryLog = new ICDAlarmIncidentRegistryLogTable();

function createKeys(hash_key, range_keys) {
  return {
    icd_alarm_incident_registry_id: hash_key,
    delivery_medium_status: createCompoundRangeKey(range_keys)
  };
}

function createCompoundRangeKey(keys) {
  return parseInt(keys.delivery_medium.toString() + keys.status.toString(), 10);
}

function addCompoundRangeKey(data) {
  let { delivery_medium, status } = data;
  data.delivery_medium_status = createCompoundRangeKey({ delivery_medium, status });
  return data;
}


/**
 * Retrieve one ICDAlarmIncidentRegistryLog.
 */
export function retrieve(req, res, next) {

  let { icd_alarm_incident_registry_id, delivery_medium, status } = req.params;
  let keys = createKeys(icd_alarm_incident_registry_id, { delivery_medium, status });

  ICDAlarmIncidentRegistryLog.retrieve(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result.Item);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one ICDAlarmIncidentRegistryLog.
 */
export function create(req, res, next) {

  let data = req.body;

  ICDAlarmIncidentRegistryLog.create(data)
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one ICDAlarmIncidentRegistryLog.
 *
 * NOTE: this needs to be revisited and revised to encorporate proper log rules.
 * 
 */
export function createFromWebHook(req, res, next) {

  let data = req.body;

  ICDAlarmIncidentRegistryLog.create(data)
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });
}

// NOTE: we don't need full CRUD for now.
// /**
//  * Update one item.  (replace)
//  */
// export function update(req, res, next) {

//   const { icd_alarm_incident_registry_id, delivery_medium_status } = req.params;

//   // Add url keys into request body.
//   req.body.icd_alarm_incident_registry_id = icd_alarm_incident_registry_id;
//   req.body.delivery_medium_status = delivery_medium_status;

//   // Revise validation for update.
//   let ICDAlarmIncidentRegistryLogValidationSchemaUpdate = { ...ICDAlarmIncidentRegistryLogValidationSchema };
//   ICDAlarmIncidentRegistryLogValidationSchemaUpdate.icd_alarm_incident_registry_id = {
//     notEmpty: { errorMessage: 'ICDAlarmIncidentRegistryLog identifier required.' },
//     isUUID: { errorMessage: 'Valid ICDAlarmIncidentRegistryLog ID required.' }
//   };
//   ICDAlarmIncidentRegistryLogValidationSchemaUpdate.delivery_medium_status = {
//     notEmpty: { errorMessage: 'ICDAlarmIncidentRegistryLog sort key required.' },
//     isUUID: { errorMessage: 'Valid ICDAlarmIncidentRegistryLog sort key required.' }
//   };

//   req.checkBody(ICDAlarmIncidentRegistryLogValidationSchemaUpdate);
//   let validationErrors = req.validationErrors();
//   validationErrors = allow(ICDAlarmIncidentRegistryLogFields, req.body, validationErrors);

//   if(validationErrors) {
//     return res.status(400).send({ error: true, message: "Validation errors.",
//                                   fieldErrors: validationErrors });
//   } else {

//     ICDAlarmIncidentRegistryLog.update(req.body)
//       .then(result => {
//         res.json(result);
//       })
//       .catch(err => {
//         next(err);
//       });
//   }
// }

// /**
//  * Patch one ICDAlarmIncidentRegistryLog.  Use this to update individual fields.
//  */
// export function patch(req, res, next) {

//   const { icd_alarm_incident_registry_id, delivery_medium_status } = req.params;
//   let keys = { icd_alarm_incident_registry_id, delivery_medium_status };

//   // Revise validation for update.
//   let paramSchema = {
//     icd_alarm_incident_registry_id: {
//       notEmpty: { errorMessage: 'ICDAlarmIncidentRegistryLog identifier required.' },
//       isUUID: { errorMessage: 'Valid ICDAlarmIncidentRegistryLog ID required.' }
//     },
//     delivery_medium_status: {
//       notEmpty: { errorMessage: 'ICDAlarmIncidentRegistryLog sort key required.' },
//       isUUID: { errorMessage: 'Valid ICDAlarmIncidentRegistryLog sort key required.' }
//     }
//   };

//   // Validate.
//   req.checkParams(paramSchema);
//   req.checkBody(ICDAlarmIncidentRegistryLogValidationSchema);
//   let validationErrors = req.validationErrors();
//   validationErrors = allow(ICDAlarmIncidentRegistryLogFields, req.body, validationErrors);

//   if(validationErrors) {
//     return res.status(400).send({ error: true, message: "Validation errors.",
//                                   fieldErrors: validationErrors });
//   } else {

//     ICDAlarmIncidentRegistryLog.patch(keys, req.body)
//       .then(result => {
//         res.json(result);
//       })
//       .catch(err => {
//         next(err);
//       });
//   }
// }

// /**
//  * Delete one ICDAlarmIncidentRegistryLog.
//  */
// export function remove(req, res, next) {

//   const { icd_alarm_incident_registry_id, delivery_medium_status } = req.params;
//   let keys = { icd_alarm_incident_registry_id, delivery_medium_status };

//   ICDAlarmIncidentRegistryLog.remove(keys)
//     .then(result => {
//       if(!result) {
//         next({ status: 404, message: "Item not found."  });
//       } else {
//         res.json(result);
//       }
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Archive ('delete') one ICDAlarmIncidentRegistryLog.
//  */
// export function archive(req, res, next) {

//   const { icd_alarm_incident_registry_id, delivery_medium_status } = req.params;
//   let keys = { icd_alarm_incident_registry_id, delivery_medium_status };

//   ICDAlarmIncidentRegistryLog.archive(keys)
//     .then(result => {
//       if(_.isEmpty(result)) {
//         next({ status: 404, message: "Item not found."  });
//       } else {
//         // Returns: { Attributes: { is_deleted: true } }
//         res.json(result);
//       }
//     })
//     .catch(err => {
//       next(err);
//     });
// }

/**
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  ICDAlarmIncidentRegistryLog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDAlarmIncidentRegistryLog by icd_alarm_incident_registry_id.
 */
export function retrieveByIncidentId(req, res, next) {

  const { icd_alarm_incident_registry_id } = req.params;
  ICDAlarmIncidentRegistryLog.retrieveByIncidentId({ icd_alarm_incident_registry_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDAlarmIncidentRegistryLog by receipt_id.
 */
export function retrieveByReceiptId(req, res, next) {

  const { receipt_id } = req.params;
  ICDAlarmIncidentRegistryLog.retrieveByReceiptId({ receipt_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
