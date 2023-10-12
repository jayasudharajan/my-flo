import _ from 'lodash';
import moment from 'moment';
import EmailDeliveryLogTable from '../models/EmailDeliveryLogTable';
let emailDeliveryLog = new EmailDeliveryLogTable();

/**
 * Retrieve one emailDeliveryLog.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  emailDeliveryLog.retrieve(keys)
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
 * Create one emailDeliveryLog.
 */
export function create(req, res, next) {

  emailDeliveryLog.create(req.body)
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

  emailDeliveryLog.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one emailDeliveryLog.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  emailDeliveryLog.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one emailDeliveryLog.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  emailDeliveryLog.remove(keys)
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
 * Archive ('delete') one emailDeliveryLog.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  emailDeliveryLog.archive(keys)
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

  emailDeliveryLog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query by receipt_id.
 */
export function retrieveByReceiptId(req, res, next) {

  const { receipt_id } = req.params;
  emailDeliveryLog.retrieveByReceiptId({ receipt_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
