import _ from 'lodash';
import PKILogTable from '../models/PKILogTable';
let PKILog = new PKILogTable();

/**
 * Retrieve one PKILog.
 */
export function retrieve(req, res, next) {

  const { task_id, created_at } = req.params;
  let keys = { task_id, created_at };

  PKILog.retrieve(keys)
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
 * Create one PKILog.
 */
export function create(req, res, next) {

  PKILog.createLatest(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { task_id, created_at } = req.params;

  // Add url keys into request body.
  req.body.task_id = task_id;
  req.body.created_at = created_at;

  PKILog.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one PKILog.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { task_id, created_at } = req.params;
  let keys = { task_id, created_at };

  PKILog.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one PKILog.
 */
export function remove(req, res, next) {

  const { task_id, created_at } = req.params;
  let keys = { task_id, created_at };

  PKILog.remove(keys)
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
 * Archive ('delete') one PKILog.
 */
export function archive(req, res, next) {

  const { task_id, created_at } = req.params;
  let keys = { task_id, created_at };

  PKILog.archive(keys)
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

  PKILog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set PKILog with same hashkey.
 */
export function retrieveByTaskId(req, res, next) {

  const { task_id } = req.params;
  PKILog.retrieveByTaskId({ task_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
