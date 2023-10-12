import _ from 'lodash';
import ICDAlarmNotificationStatusRegistryTable from '../models/ICDAlarmNotificationStatusRegistryTable';
let ICDAlarmNotificationStatusRegistry = new ICDAlarmNotificationStatusRegistryTable();


/**
 * Retrieve one ICDAlarmNotificationStatusRegistry.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmNotificationStatusRegistry.retrieve(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        res.status(404).send({ error: true, message: "Item not found." });
      } else {
        res.json(result.Item);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one ICDAlarmNotificationStatusRegistry.
 */
export function create(req, res, next) {
 
  ICDAlarmNotificationStatusRegistry.create(mapEmptyToNull(req.body))
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });
}

function mapEmptyToNull(obj) {
  return  _.mapValues(obj, val => _.isObject(val) ? mapEmptyToNull(val) : (val === '' ? null : val));
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { id } = req.params;

  // Add url keys into request body.
  req.body.id = id;


  ICDAlarmNotificationStatusRegistry.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one ICDAlarmNotificationStatusRegistry.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmNotificationStatusRegistry.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one ICDAlarmNotificationStatusRegistry.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmNotificationStatusRegistry.remove(keys)
    .then(result => {
      if(!result) {
        res.status(404).send({ error: true, message: "Item not found." });
      } else {
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Archive ('delete') one ICDAlarmNotificationStatusRegistry.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmNotificationStatusRegistry.archive(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        res.status(404).send({ error: true, message: "Item not found." });
      } else {
        // Returns: { Attributes: { is_deleted: true } }
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDAlarmNotificationStatusRegistry GSI icd_id with same hashkey.
 */
export function retrieveByIcdId(req, res, next) {

  const { icd_id } = req.params;
  ICDAlarmNotificationStatusRegistry.retrieveByIcdId({ icd_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDAlarmNotificationStatusRegistry GSI icd_id with same hashkey & rangekey.
 */
export function retrieveByIcdIdAndIncidentTime(req, res, next) {

  const { icd_id, incident_time } = req.params;
  ICDAlarmNotificationStatusRegistry.retrieveByIcdIdAndIncidentTime({ icd_id, incident_time })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveByIcdAlarmIncidentRegistryId(req, res, next) {

  const { icd_alarm_incident_registry_id } = req.params;
  ICDAlarmNotificationStatusRegistry.retrieveByIcd_id({ icd_alarm_incident_registry_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveByIcdAlarmIncidentRegistryIdAndIncidentTime(req, res, next) {

  const { icd_alarm_incident_registry_id, incident_time } = req.params;
  ICDAlarmNotificationStatusRegistry.retrieveByIcd_id({ icd_alarm_incident_registry_id, incident_time })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
