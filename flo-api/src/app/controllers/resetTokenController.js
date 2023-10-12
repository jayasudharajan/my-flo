import _ from 'lodash';
import ResetTokenTable from '../models/ResetTokenTable';
let resetToken = new ResetTokenTable();

/**
 * Retrieve one resetToken.
 */
export function retrieve(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  resetToken.retrieve(keys)
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
 * Create one resetToken.
 */
export function create(req, res, next) {

  resetToken.create(req.body)
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

  const { user_id } = req.params;

  // Add url keys into request body.
  req.body.user_id = user_id;

  resetToken.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one resetToken.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  resetToken.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one resetToken.
 */
export function remove(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  resetToken.remove(keys)
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
 * Archive ('delete') one resetToken.
 */
export function archive(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };
  
  resetToken.archive(keys)
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

  resetToken.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}
