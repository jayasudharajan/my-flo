import _ from 'lodash';
import UserLocationRoleTable from '../models/UserLocationRoleTable';
let userLocationRole = new UserLocationRoleTable();

/**
 * Retrieve one userLocationRole.
 */
export function retrieve(req, res, next) {

  const { user_id, location_id } = req.params;
  let keys = { user_id, location_id };

  userLocationRole.retrieve(keys)
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
 * Create one userLocationRole.
 */
export function create(req, res, next) {

  userLocationRole.create(req.body)
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

  const { user_id, location_id } = req.params;

  // Add url keys into request body.
  req.body.user_id = user_id;
  req.body.location_id = location_id;

  userLocationRole.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one userLocationRole.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id, location_id } = req.params;
  let keys = { user_id, location_id };

  userLocationRole.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one userLocationRole.
 */
export function remove(req, res, next) {

  const { user_id, location_id } = req.params;
  let keys = { user_id, location_id };

  userLocationRole.remove(keys)
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
 * Archive ('delete') one userLocationRole.
 */
export function archive(req, res, next) {

  const { user_id, location_id } = req.params;
  let keys = { user_id, location_id };
  
  userLocationRole.archive(keys)
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

  userLocationRole.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query userLocationRole by user_id.
 */
export function retrieveByUserId(req, res, next) {

  const { user_id } = req.params;
  userLocationRole.retrieveByUserId({ user_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query userLocationRole by account_id.
 */
export function retrieveByLocationId(req, res, next) {

  const { location_id } = req.params;
  userLocationRole.retrieveByLocationId({ location_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
