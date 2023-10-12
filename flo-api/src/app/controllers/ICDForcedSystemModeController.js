import _ from 'lodash';
import ICDForcedSystemModeTable from '../models/ICDForcedSystemModeTable';
import { lookupByDeviceId } from '../../util/icdUtils';
let ICDForcedSystemMode = new ICDForcedSystemModeTable();

// Allowed fields for ICDForcedSystemMode.
let ICDForcedSystemModeFields = [
  // TODO: put in allowed fields.
  'icd_id', 'created_at'
];

// Validation.
let ICDForcedSystemModeValidationSchema = {
  // TODO: put in field validation.
  // See: https://github.com/ctavan/express-validator
  //'samplefield': { optional: true, isUUID: { errorMessage: 'Valid User ID required.' } },
}

/**
 * Retrieve one ICDForcedSystemMode.
 */
export function retrieve(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDForcedSystemMode.retrieve(keys)
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
 * Create one ICDForcedSystemMode.
 */
export function create(req, res, next) {

  // Validate.
  req.checkBody(ICDForcedSystemModeValidationSchema);
  let validationErrors = req.validationErrors();
  validationErrors = allow(ICDForcedSystemModeFields, req.body, validationErrors);

  if(validationErrors) {
    return res.status(400).send({ error: true, message: "Validation errors.",
                                  fieldErrors: validationErrors });
  } else {

    ICDForcedSystemMode.create(req.body)
      .then(result => {
        res.json(result); // For a successful create - this will return an empty collection.
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { icd_id, created_at } = req.params;

  // Add url keys into request body.
  req.body.icd_id = icd_id;
  req.body.created_at = created_at;

  // Revise validation for update.
  let ICDForcedSystemModeValidationSchemaUpdate = { ...ICDForcedSystemModeValidationSchema };
  ICDForcedSystemModeValidationSchemaUpdate.icd_id = {
    notEmpty: { errorMessage: 'ICDForcedSystemMode identifier required.' },
    isUUID: { errorMessage: 'Valid ICDForcedSystemMode ID required.' }
  };
  ICDForcedSystemModeValidationSchemaUpdate.created_at = {
    notEmpty: { errorMessage: 'ICDForcedSystemMode sort key required.' },
    isUUID: { errorMessage: 'Valid ICDForcedSystemMode sort key required.' }
  };

  req.checkBody(ICDForcedSystemModeValidationSchemaUpdate);
  let validationErrors = req.validationErrors();
  validationErrors = allow(ICDForcedSystemModeFields, req.body, validationErrors);

  if(validationErrors) {
    return res.status(400).send({ error: true, message: "Validation errors.",
                                  fieldErrors: validationErrors });
  } else {

    ICDForcedSystemMode.update(req.body)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Patch one ICDForcedSystemMode.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  // Revise validation for update.
  let paramSchema = {
    icd_id: {
      notEmpty: { errorMessage: 'ICDForcedSystemMode identifier required.' },
      isUUID: { errorMessage: 'Valid ICDForcedSystemMode ID required.' }
    },
    created_at: {
      notEmpty: { errorMessage: 'ICDForcedSystemMode sort key required.' },
      isUUID: { errorMessage: 'Valid ICDForcedSystemMode sort key required.' }
    }
  };

  // Validate.
  req.checkParams(paramSchema);
  // if there is empty check in ICDForcedSystemModeValidationSchema,
  // please create another schema for patch check.
  // patch is partial update method, doesn't need all attributes.
  req.checkBody(ICDForcedSystemModeValidationSchema);
  let validationErrors = req.validationErrors();
  validationErrors = allow(ICDForcedSystemModeFields, req.body, validationErrors);

  if(validationErrors) {
    return res.status(400).send({ error: true, message: "Validation errors.",
                                  fieldErrors: validationErrors });
  } else {

    ICDForcedSystemMode.patch(keys, req.body)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Delete one ICDForcedSystemMode.
 */
export function remove(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDForcedSystemMode.remove(keys)
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
 * Archive ('delete') one ICDForcedSystemMode.
 */
export function archive(req, res, next) {

  const { icd_id, created_at } = req.params;
  let keys = { icd_id, created_at };

  ICDForcedSystemMode.archive(keys)
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

  ICDForcedSystemMode.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDForcedSystemMode with same hashkey.
 */
export function retrieveByIcdId(req, res, next) {

  const { icd_id } = req.params;
  ICDForcedSystemMode.retrieveByIcdId({ icd_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}


export function retrieveLatestByIcdId(req, res, next) {

  const { icd_id } = req.params;
  ICDForcedSystemMode.retrieveLatestByIcdId({ icd_id })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveLatestByDeviceId(req, res, next) {
  const { device_id } = req.params;

  lookupByDeviceId(device_id, req.log)
    .then(({ id: icd_id }) => {
      return ICDForcedSystemMode.retrieveLatestByIcdId({ icd_id });
    })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    })
}