import _ from 'lodash';
import AccountTable from '../models/AccountTable';
let account = new AccountTable();

/**
 * Retrieve one account.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  account.retrieve(keys)
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
 * Create one account.
 */
export function create(req, res, next) {

  account.create(req.body)
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

  account.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one account.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  account.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one account.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  account.remove(keys)
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
 * Archive ('delete') one account.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  account.archive(keys)
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

  account.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Retrieve accounts with same group_id.
 */
export function retrieveAccountsForGroup(req, res, next) {
  const { group_id } = req.params;
  account.retrieveAccountsForGroup({ group_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Retrieve accounts with same owner_user_id.
 */
export function retrieveAccountsForOwner(req, res, next) {
  const { owner_user_id } = req.params;
  account.retrieveAccountsForOwner({ owner_user_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
