import _ from 'lodash';
import AccountGroupTable from '../models/AccountGroupTable';
let AccountGroup = new AccountGroupTable();

/**
 * Retrieve one AccountGroup.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  AccountGroup.retrieve(keys)
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
 * Create one AccountGroup.
 */
export function create(req, res, next) {

  AccountGroup.create(req.body)
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

  AccountGroup.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one AccountGroup.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  AccountGroup.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one AccountGroup.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  AccountGroup.remove(keys)
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
 * Archive ('delete') one AccountGroup.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  AccountGroup.archive(keys)
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

  AccountGroup.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}
