import _ from 'lodash';
import UserAccountGroupRoleTable from '../models/UserAccountGroupRoleTable';
let UserAccountGroupRole = new UserAccountGroupRoleTable();

/**
 * Retrieve one UserAccountGroupRole.
 */
export function retrieve(req, res, next) {

  const { user_id, group_id } = req.params;
  let keys = { user_id, group_id };

  UserAccountGroupRole.retrieve(keys)
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
 * Create one UserAccountGroupRole.
 */
export function create(req, res, next) {

  UserAccountGroupRole.create(req.body)
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

  const { user_id, group_id } = req.params;

  // Add url keys into request body.
  req.body.user_id = user_id;
  req.body.group_id = group_id;

  UserAccountGroupRole.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one UserAccountGroupRole.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id, group_id } = req.params;
  let keys = { user_id, group_id };

  UserAccountGroupRole.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one UserAccountGroupRole.
 */
export function remove(req, res, next) {

  const { user_id, group_id } = req.params;
  let keys = { user_id, group_id };

  UserAccountGroupRole.remove(keys)
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
 * Archive ('delete') one UserAccountGroupRole.
 */
export function archive(req, res, next) {

  const { user_id, group_id } = req.params;
  let keys = { user_id, group_id };

  UserAccountGroupRole.archive(keys)
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

  UserAccountGroupRole.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set UserAccountGroupRole with same hashkey.
 */
export function retrieveByUserId(req, res, next) {

  const { user_id } = req.params;
  UserAccountGroupRole.retrieveByUserId({ user_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
