import _ from 'lodash';
import ICDAlarmIncidentRegistryTable from '../models/ICDAlarmIncidentRegistryTable';
import ICDTable from '../models/ICDTable';
let ICDAlarmIncidentRegistry = new ICDAlarmIncidentRegistryTable();
let ICD = new ICDTable();

/**
 * Retrieve one ICDAlarmIncidentRegistry.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmIncidentRegistry.retrieve(keys)
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
 * Create one ICDAlarmIncidentRegistry.
 */
export function create(req, res, next) {

  ICDAlarmIncidentRegistry.create(req.body)
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });  
  
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { id } = req.params;
  // Add url keys into request body.
  req.body.id = id;

  ICDAlarmIncidentRegistry.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one ICDAlarmIncidentRegistry.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmIncidentRegistry.patch(keys, _.omit(req.body, Object.keys(keys)))
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one ICDAlarmIncidentRegistry.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICDAlarmIncidentRegistry.remove(keys)
    .then(result => {
      if(!result) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Archive ('delete') one ICDAlarmIncidentRegistry.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  ICDAlarmIncidentRegistry.archive(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
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
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {
  let { limit, id } = req.params;
  let keys = {};
  if(!_.isUndefined(limit)) limit = parseInt(limit);
  if(!_.isUndefined(id)) keys = { id };

  if(_.isNaN(limit)) {
    next({ status: 400, message: 'Invalid limit number.' });
  } else {
    ICDAlarmIncidentRegistry.scanAll(limit, keys)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Get a list of incidents by icd_id.
 */
export function retrieveByICDId(req, res, next) {
  let { icd_id, limit, id, acknowledged_by_user } = req.params;
  let keys = {};

  if(!_.isUndefined(limit)) limit = parseInt(limit);
  if(!_.isUndefined(id) && !_.isUndefined(acknowledged_by_user)) keys = { id, acknowledged_by_user: parseInt(acknowledged_by_user) };

  ICDAlarmIncidentRegistry.retrieveByICDId({ icd_id }, limit, keys)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Get a list of incidents by icd_id, sort by time.
 */
export function retrieveNewestByICDId(req, res, next) {
  let { icd_id, limit } = req.params;
  let cursor = req.body;

  limit = (limit) ? parseInt(limit) : limit;

  ICDAlarmIncidentRegistry.retrieveNewestByICDId({ icd_id }, limit, cursor)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}

export function retrieveByICDIdIncidentTime(req, res, next) {
  const { icd_id, count, id } = req.params;
  const limit = parseInt(count) + 1;

  ICDAlarmIncidentRegistry.retrieveByICDIdIncidentTime({ icd_id }, limit, id)
    .then(result => {
      const rows = result.Items.slice(0, limit - 1);
      const data = {
        Items: rows,
        LastKey: _.has(result, 'LastEvaluatedKey')? _.pick(_.last(rows), ['id']): undefined
      };
      res.json(data);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get a list of incidents by icd_id.
 */
export function retrieveByDeviceId(req, res, next) {

  const { device_id } = req.params;

  ICD.retrieveByDeviceId({ device_id })
    .then(icdResult => {
      if(_.isEmpty(icdResult.Items)) {
        return new Promise((resolve, reject) => { reject({status: 400, message: 'ICD not found.' }) });
      } else {
        return ICDAlarmIncidentRegistry.retrieveByICDId({ icd_id: icdResult.Items[0].id })
      }
    })
    .then(result => {
      if(_.isEmpty(result.Items)) {
        res.json([]);        
      } else {
        res.json(result.Items);
      }
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Get a list of incidents by icd_id that are unacknowledged by the user.
 */
export function retrieveUnacknowledgedByICDId(req, res, next) {

  const { icd_id } = req.params;

  ICDAlarmIncidentRegistry.retrieveUnacknowledgedByICDId({ icd_id })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Get a list of incidents by icd_id that are unacknowledged by the user.
 */
export function setAcknowledgedByICDId(req, res, next) {

  const { icd_id } = req.params;

  ICDAlarmIncidentRegistry.setAcknowlegedByICDId({ icd_id })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Get the highest severity incident by icd_id that is unacknowledged.
 *
 * TODO: THIS IS DEPRECATED AND WARRANTS REMOVAL - SM - 8.31.2016.
 *   Most severe is now via AlarmNotificationDeliveryFilter.
 */
export function retrieveHighestSeverityByICDId(req, res, next) {

  const { icd_id } = req.params;

  ICDAlarmIncidentRegistry.retrieveHighestSeverityByICDId({ icd_id })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}
