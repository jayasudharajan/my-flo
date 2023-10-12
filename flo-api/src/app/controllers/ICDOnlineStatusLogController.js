import _ from 'lodash';
import ICDOnlineStatusLogTable from '../models/ICDOnlineStatusLogTable';
import { lookupByDeviceId } from '../../util/icdUtils';
let ICDOnlineStatusLog = new ICDOnlineStatusLogTable();


/**
 * Retrieve one ICDOnlineStatusLog.
 */
export function retrieve(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDOnlineStatusLog.retrieve(keys)
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
 * Create one ICDOnlineStatusLog.
 */
export function create(req, res, next) {

  ICDOnlineStatusLog.create(req.body)
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

  const { icd_id, created_at } = req.params;

  // Add url keys into request body.
  req.body.icd_id = icd_id;
  req.body.created_at = created_at;

  ICDOnlineStatusLog.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one ICDOnlineStatusLog.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDOnlineStatusLog.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Delete one ICDOnlineStatusLog.
 */
export function remove(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDOnlineStatusLog.remove(keys)
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
 * Archive ('delete') one ICDOnlineStatusLog.
 */
export function archive(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDOnlineStatusLog.archive(keys)
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
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  ICDOnlineStatusLog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDOnlineStatusLog with same hashkey.
 */
export function retrieveByIcdId(req, res, next) {

  const { icd_id } = req.params;
  ICDOnlineStatusLog.retrieveByIcdId({ icd_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

export function logDeviceStatus(req, res, next) {
  const { device_id, status } = req.params;

  lookupByDeviceId(device_id)
    .then(({ id: icd_id }) => ICDOnlineStatusLog.createLatest({ icd_id, device_id, status, data: req.body }))
    .then(result => res.json(result))
    .catch(err => next(err));
}

