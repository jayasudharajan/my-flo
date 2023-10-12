import _ from 'lodash';
import KernelVersionTable from '../models/KernelVersionTable';
let kernelVersion = new KernelVersionTable();

/**
 * Retrieve one kernelVersion.
 */
export function retrieve(req, res, next) {

  const { model, version } = req.params;
  let keys = { model, version };

  kernelVersion.retrieve(keys)
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
 * Create one kernelVersion.
 */
export function create(req, res, next) {

  kernelVersion.create(req.body)
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

  const { model, version } = req.params;

  // Add url keys into request body.
  req.body.model = model;
  req.body.version = version;

  kernelVersion.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one KernelVersion.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { model, version } = req.params;
  let keys = { model, version };

  kernelVersion.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one kernelVersion.
 */
export function remove(req, res, next) {

  const { model, version } = req.params;
  let keys = { model, version };

  kernelVersion.remove(keys)
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
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  kernelVersion.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set kernelVersion with same hashkey.
 */
export function queryPartition(req, res, next) {

  const { model } = req.params;
  kernelVersion.queryPartition({ model })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
