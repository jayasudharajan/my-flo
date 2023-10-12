import _ from 'lodash';
import UserDetailTable from '../models/UserDetailTable';
let userDetail = new UserDetailTable();

/**
 * Retrieve one userDetail.
 */
export function retrieve(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  userDetail.retrieve(keys)
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
 * Get User + UserDetail info.
 */
export function retrieveWithUser(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  userDetail.retrieveWithUser(user_id)
    .then(result => {
      if(_.isEmpty(result)) {
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
 * Create one userDetail.
 */
export function create(req, res, next) {

  userDetail.create(req.body)
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

  userDetail.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one userDetail.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  userDetail.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one userDetail.
 */
export function remove(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };

  userDetail.remove(keys)
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
 * Archive ('delete') one userDetail.
 */
export function archive(req, res, next) {

  const { user_id } = req.params;
  let keys = { user_id };
  
  userDetail.archive(keys)
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

  userDetail.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}
