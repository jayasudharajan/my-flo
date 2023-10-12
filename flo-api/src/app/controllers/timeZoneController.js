import _ from 'lodash';
import TimeZoneTable from '../models/TimeZoneTable';
let timeZone = new TimeZoneTable();

/**
 * Retrieve one timeZone.
 */
export function retrieve(req, res, next) {

  const { tz } = req.params;
  let keys = { tz };

  timeZone.retrieve(keys)
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
 * Get all active Timezones.
 */
export function retrieveActive(req, res, next) {

  timeZone.retrieveActive()
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
 * Create one timeZone.
 */
export function create(req, res, next) {

  timeZone.create(req.body)
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

  const { tz } = req.params;
  // Add url keys into request body.
  req.body.tz = tz;

  timeZone.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one timeZone.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { tz } = req.params;
  let keys = { tz };

  timeZone.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one timeZone.
 */
export function remove(req, res, next) {

  const { tz } = req.params;
  let keys = { tz };

  timeZone.remove(keys)
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
 * Archive ('delete') one timeZone.
 */
export function archive(req, res, next) {

  const { tz } = req.params;
  let keys = { tz };

  timeZone.archive(keys)
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

  timeZone.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}
