import _ from 'lodash';
import UserAccountRoleTable from '../models/UserAccountRoleTable';
let userAccountRole = new UserAccountRoleTable();

/**
 * Retrieve one userAccountRole.
 */
export function retrieve(req, res, next) {

  const { user_id, account_id } = req.params;
  let keys = { user_id, account_id };

  userAccountRole.retrieve(keys)
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
 * Create one userAccountRole.
 */
export function create(req, res, next) {

  userAccountRole.create(req.body)
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

  const { user_id, account_id } = req.params;

  // Add url keys into request body.
  req.body.user_id = user_id;
  req.body.account_id = account_id;

  userAccountRole.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one userAccountRole.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id, account_id } = req.params;
  let keys = { user_id, account_id };

  userAccountRole.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one userAccountRole.
 */
export function remove(req, res, next) {

  const { user_id, account_id } = req.params;
  let keys = { user_id, account_id };

  userAccountRole.remove(keys)
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
 * Archive ('delete') one userAccountRole.
 */
export function archive(req, res, next) {

  const { user_id, account_id } = req.params;
  let keys = { user_id, account_id };
  
  userAccountRole.archive(keys)
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

  userAccountRole.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query userAccountRole by user_id.
 */
export function retrieveByUserId(req, res, next) {

  const { user_id } = req.params;
  userAccountRole.retrieveByUserId({ user_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query userAccountRole by account_id.
 */
export function retrieveByAccountId(req, res, next) {

  const { account_id } = req.params;
  userAccountRole.retrieveByAccountId({ account_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
