import _ from 'lodash';
import moment from 'moment-timezone';
import ICDTable from '../models/ICDTable';
import LocationTable from '../models/LocationTable';
import ICDAlarmIncidentRegistryTable from '../models/ICDAlarmIncidentRegistryTable';
import AlarmNotificationDeliveryFilterTable from '../models/AlarmNotificationDeliveryFilterTable';
import ICDAlarmNotificationDeliveryRuleTable from '../models/ICDAlarmNotificationDeliveryRuleTable';
import { lookupByICDId, lookupByDeviceId, lookupByLocationId,
        scanAllUserDevice, fetchAllGroupUserDevice,
        searchUserDevice, searchGroupUserDevice } from '../../util/icdUtils';
import directives from '../../util/directives';
import uuid from 'node-uuid';
import { updateAlarmWithUserAction } from '../../util/alarmUtils';
import { handleExternalAction as _handleExternalAction } from '../../util/externalActions';
import { getICDsByTimezone } from '../../util/elasticSearchICDQueryGenerator';
import { client as esClient } from '../../util/elasticSearchProxy';
import * as pes from '../services/pes/pes';
let ICD = new ICDTable();
let ICDAlarmIncidentRegistry = new ICDAlarmIncidentRegistryTable();
let AlarmNotificationDeliveryFilter = new AlarmNotificationDeliveryFilterTable();
let ICDAlarmNotificationDeliveryRule = new ICDAlarmNotificationDeliveryRuleTable();
let Location = new LocationTable();

/**
 * Retrieve one ICD.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICD.retrieve(keys)
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
 * Retrieve ICDs by location id. Uses GSI
 */
export function retrieveByLocationId(req, res, next) {
  const { location_id } = req.params;
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
          // return multiple items. a GSI returns result.Items
          res.json(result.Items);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Retrieve ICDs by location id. Just return the first one that is found.
 */
export function retrieveOne(req, res, next) {
  const { location_id } = req.params;
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
          res.json(result.Items[0]);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Retrieve one ICD by device id. Uses GSI
 */
export function retrieveByDeviceId(req, res, next) {
  const { device_id } = req.params;
  ICD.retrieveByDeviceId({ device_id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        // return as single item. a GSI returns result.Items
        res.json(result.Items[0]);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Return an array of user_id(s) based on relation to device_id.
 */
export function retrieveUserIdsByDeviceId(req, res, next) {
  const { device_id } = req.params;

  ICD.retrieveUserIdsByDeviceId({ device_id })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}


/**
 * Create one ICD.
 */
export function create(req, res, next) {

  ICD.create(req.body)
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

  ICD.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create OR Update an ICD if id is present.  Assumes location_id is set from auth token.
 */
export function createOrUpdate(req, res, next) {
  const { id, device_id } = req.body;
  const { location_id, user_id } = req.params;

  (
    !id ? 
      pairDevice({ device_id, location_id, user_id, app_used: req.app_used, log: req.log }) :
      ICD.update({ id }, req.body) 
  )
  .then(result => res.json(result))
  .catch(err => next(err));
}

function pairDevice({ device_id, location_id, user_id, app_used, log }) {
  return Promise.all([
    ICD.retrieveByLocationId({ location_id }), 
    ICD.retrieveByDeviceId({ device_id })
  ])  
  .then(([{ Items: locationIdResults }, { Items: deviceIdResults }]) => {
    const isUserPairedPrior = (locationIdResults || []).some(({ is_paired }) => is_paired);
    const isDevicePairedPrior = (deviceIdResults || []).some(({ is_paired }) => is_paired);

    if (isUserPairedPrior) {
      throw { status: 400, message: 'User is already paired.' };
    } if (isDevicePairedPrior) {
      throw { status: 400, message: 'Device is already paired.' };
    }

    return Promise.all([
      ICD.create({ id: uuid.v4(), is_paired: true, device_id, location_id }),
      Location.retrieveByLocationId({ location_id })
    ])
  })
  .then(([result, { Items: locations }]) => {
   return directives(user_id, app_used, log).enableForcedSleep({ device_id })
    .then(() => result)
    .catch(err => {
      // Forced sleep is a non-fatal error. Log and proceed.
      log.error({ err });
      return new Promise(resolve => resolve(result));
    });
  });
}

/**
 * Patch one ICD.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICD.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one ICD.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  ICD.remove(keys)
    .then(result => {
      if(!result) {
        throw { status: 404, message: "Item not found."  };
      } else {
        return pes.deleteDevice(result.Attributes.device_id)
          .then(() => result)
          .catch(err => {
            req.log.error({ err });
            return new Promise(resolve => resolve(result));
          });
      }
    })
    .then(result => res.json(result))
    .catch(next);
}

/**
 * Archive ('delete') one ICD.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  ICD.archive(keys)
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

  ICD.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get all incidents for the FIRST ICD in a Location.
 */
export function retrieveAlarmsByLocationIdUTC(req, res, next) {

  const { location_id } = req.params;

  // NOTE: Getting FIRST ICD based on location.
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result.Items)) {
        res.status(200).send([]);
      } else {
        return ICDAlarmIncidentRegistry.retrieveUnacknowledgedByICDId({ icd_id: result.Items[0].id });
      }
    })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get all incidents for the FIRST ICD in a Location.
 */
export function retrieveAlarmsByLocationId(req, res, next) {

  const { location_id } = req.params;

  // NOTE: Getting FIRST ICD based on location.
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result.Items)) {
        res.status(200).send([]);
      } else {
        return ICDAlarmIncidentRegistry.retrieveUnacknowledgedByICDId({ icd_id: result.Items[0].id });
      }
    })
    .then(result => {

      // Return 'local' time for date items.
      let rows = result.Items;
      rows.forEach(row => {
        if(row.created_at && row.icd_data && row.icd_data.timezone) {
          row.created_at = moment(row.created_at).tz(row.icd_data.timezone).toISOString();
        }
        if(row.incident_time && row.icd_data && row.icd_data.timezone) {
          row.incident_time = moment(row.incident_time).tz(row.icd_data.timezone).toISOString();
        }
      });
      res.json(rows);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get 'most severe' incident for the FIRST ICD in a Location.
 */
export function retrieveMostSevereAlarmByLocationId(req, res, next) {

  const { location_id } = req.params;

  // NOTE: Getting FIRST ICD based on location.
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result.Items)) {
        next({ status: 400, message: "No ICD found." });
      } else {

        // Get 'most severe unresolved alarm'.
        return AlarmNotificationDeliveryFilter
                .retrieveHighestSeverityByICDId({ icd_id: result.Items[0].id, status: 3 });

      }
    })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);        
    });

}

/**
 * Clear all incidents for the FIRST ICD in a Location.
 */
export function clearAlarmsByLocationId(req, res, next) {

  const { location_id, user_id } = req.params;
  let icd_id = '';

  // NOTE: Getting FIRST ICD based on location.
  ICD.retrieveByLocationId({ location_id })
    .then(result => {
      if(_.isEmpty(result.Items)) {
        res.status(200).send([]);
      } else {
        icd_id = result.Items[0].id;
        return AlarmNotificationDeliveryFilter.retrieveByICDIdStatus({ icd_id, status: 3 });
      }
    })
    .then(({ Items }) => {
      let filterPromises = Items.map(({ icd_id, alarm_id_system_mode }) => 
        AlarmNotificationDeliveryFilter.patch({ icd_id, alarm_id_system_mode }, {
          last_decision_user_id: user_id,
          updated_at: new Date().toISOString(),
          status: 1 // Resolved.
        })
      );
      let registryPromise = ICDAlarmIncidentRegistry.setAcknowledgedByICDId({ icd_id });

      return Promise.all([registryPromise].concat(filterPromises));
    })
    .then(([result]) => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Updates a specific incident with a user action.
 */
export function updateAlarmUserAction(req, res, next) { 
  const { action_id, incident_id, alarm_id, system_mode } = req.body;
  const { user_id, location_id, account_id } = req.params;
  const app_used = req.app_used;

  Promise.all([
      Location.retrieve({ account_id, location_id }).then(({ Item }) => Item),
      lookupByLocationId(location_id, req.log)
  ])
  .then(([locationResult, deviceLookupResult]) => {
    if (!locationResult) {
      throw { status: 404, message: 'Location not found.' };
    } 

    const { timezone } = locationResult;
    const { id: icd_id } = deviceLookupResult;

    return updateAlarmWithUserAction({
      incident_id,
      action_id,
      icd_id,
      alarm_id,
      system_mode,
      user_id,
      timezone,
      app_used
    });
  })  
  .then(result => res.json(result))
  .catch(err => next(err));

}

export function handleExternalAction(req, res, next) {
  const { user_id, device_id, action_id: actionId } = req.params;
  const action_id = parseInt(actionId);
  
  _handleExternalAction({ user_id, device_id, action_id, log: req.log })
    .then(() => res.send())
    .catch(err => next(err));
}

export function toggleValve(req, res, next) {
  let { icd_id, device_id } = req.params;
  const { user_id, valve_action, action_id: actionId } = req.params;

  (device_id ? lookupByDeviceId(device_id, req.log) : lookupByICDId(icd_id, req.log))
    .then(({ device_id, id: icd_id }) => 
        directives(user_id, req.app_used, req.log).toggleValve({ icd_id, device_id, valveaction: valve_action })
    )
    .then(() => res.send())
    .catch(err => next(err));
}

export function setSystemMode(req, res, next) {
  const { icd_id, user_id, system_mode_id } = req.params;

  return directives(user_id, req.app_used, req.log).setSystemMode({ icd_id, systemmodeid: system_mode_id})
    .then(() => res.send())
    .catch(err => next(err));
}

export function retrieveByTimezone(req, res, next) {
  const { body: { timezone }, query: { page, size } } = req;

  esClient.search(getICDsByTimezone(timezone, size, page))
    .then(({ hits: { total, hits }}) => 
      res.json({ 
        total, 
        items: hits.map(({ _source: { id, device_id } }) => ({ id, device_id })) 
      })
    )
    .catch(next);
}

export function scanUserDevice(req, res, next) {
  const { page, size } = req.query;
  scanAllUserDevice(size, page)
    .then(result => {
      res.json(result);
    })
    .catch(next);
}

export function fetchGroupUserDevice(req, res, next) {
  const { page, size } = req.query;
  const { group_id } = req.params;
  fetchAllGroupUserDevice(group_id, size, page)
    .then(result => {
      res.json(result);
    })
    .catch(next);
}

export function searchUserDevices(req, res, next) {
  const { match_string, size, page } = req.query;
  searchUserDevice(match_string, size, page)
    .then(result => {
      res.json(result);
    })
    .catch(next);
}

export function searchGroupUserDevices(req, res, next) {
  const { match_string, size, page } = req.query;
  const { group_id } = req.params;
  searchGroupUserDevice(group_id, match_string, size, page)
    .then(result => {
      res.json(result);
    })
    .catch(next);
}