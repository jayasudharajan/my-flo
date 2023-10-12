import _ from 'lodash';
import RegistrationTokenTable from '../models/RegistrationTokenTable';
let registrationToken = new RegistrationTokenTable();

/**
 * Retrieve one registrationToken.
 */
export function retrieve(req, res, next) {

  const { token1, token2 } = req.params;
  let keys = { token1, token2 };

  registrationToken.retrieve(keys)
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
 * Create one registrationToken.
 */
export function create(req, res, next) {

  registrationToken.create(req.body)
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

  const { token1, token2 } = req.params;
  // Add url keys into request body.
  req.body.token1 = token1;
  req.body.token2 = token2;

  registrationToken.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one registrationToken.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { token1, token2 } = req.params;
  let keys = { token1, token2 };

  registrationToken.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one registrationToken.
 */
export function remove(req, res, next) {

  const { token1, token2 } = req.params;
  let keys = { token1, token2 };

  registrationToken.remove(keys)
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
 * Archive ('delete') one registrationToken.
 */
export function archive(req, res, next) {

  const { token1, token2 } = req.params;
  let keys = { token1, token2 };
  
  registrationToken.archive(keys)
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

  registrationToken.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set registrationToken with same hashkey.
 */
export function queryPartition(req, res, next) {

  const { token1 } = req.params;
  registrationToken.queryPartition({ token1 })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}
