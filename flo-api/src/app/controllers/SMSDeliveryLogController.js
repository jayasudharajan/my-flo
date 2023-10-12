import _ from 'lodash';
import SMSDeliveryLogTable from '../models/SMSDeliveryLogTable';
let SMSDeliveryLog = new SMSDeliveryLogTable();

/**
 * Retrieve one SMSDeliveryLog.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  SMSDeliveryLog.retrieve(keys)
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
 * Create one SMSDeliveryLog.
 */
export function create(req, res, next) {

  SMSDeliveryLog.create(req.body)
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

  SMSDeliveryLog.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one SMSDeliveryLog.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  SMSDeliveryLog.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one SMSDeliveryLog.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  SMSDeliveryLog.remove(keys)
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
 * Archive ('delete') one SMSDeliveryLog.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  SMSDeliveryLog.archive(keys)
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

  SMSDeliveryLog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}
