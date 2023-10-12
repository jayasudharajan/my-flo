import _ from 'lodash';
import LocationTable from '../models/LocationTable';
import {getLocationEnumerationObject} from '../../util/locationUtils';

let location = new LocationTable();


/**
 * Retrieve one location.
 */
export function retrieve(req, res, next) {

  const { account_id, location_id } = req.params;
  let keys = { account_id, location_id };

  location.retrieve(keys)
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
 * Create one location.
 */
export function create(req, res, next) {

  location.create(req.body)
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

  const { account_id, location_id } = req.params;

  // Add url keys into request body.
  req.body.account_id = account_id;
  req.body.location_id = location_id;

  location.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one location.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { account_id, location_id } = req.params;
  let keys = { account_id, location_id };

  location.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one location.
 */
export function remove(req, res, next) {

  const { account_id, location_id } = req.params;
  let keys = { account_id, location_id };

  location.remove(keys)
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
 * Archive ('delete') one location.
 */
export function archive(req, res, next) {

  const { account_id, location_id } = req.params;
  let keys = { account_id, location_id };
  
  location.archive(keys)
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

  location.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query by account_id.
 */
export function retrieveByAccountId(req, res, next) {

  const { account_id } = req.params;
  location.retrieveByAccountId({ account_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query by location_id.
 */
export function retrieveByLocationId(req, res, next) {

  const { location_id } = req.params;
  location.retrieveByLocationId({ location_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
        res.json(result.Items[0]); // There should only be ONE location.
      } else {
        next({ status: 404, message: "Item not found."  });
      }
    })
    .catch(err => {
      next(err);
    });
}


/**
 * Enumeration endpoints
 * */
export function retrieveLocationEnumeration(req, res, next) {
    res.json(getLocationEnumerationObject());
}
