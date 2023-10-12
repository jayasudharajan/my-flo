import _ from 'lodash';
import UserUtilsTable from '../models/UserUtilsTable';
import ElasticSearchUsers from '../../util/ElasticSearchUsers';
import { filterUser } from '../../util/httpUtil';
import { checkPassword } from '../../util/utils';
import { makeSearchResponse } from '../../util/elasticSearchHelper';

let userUtils = new UserUtilsTable();
const elasticSearchUsers = new ElasticSearchUsers();

// Allowed fields for the userDetail table.
let fields = [
  // common fields
  'user_id',    // named 'id' in user
  // user
  'email',
  'is_active',
  'password',
  'reset_password_token',
  'is_deleted',
  // user detail
  'prefixname',
  'firstname',
  'middlename',
  'lastname',
  'suffixname',
  'phone_primary',
  'phone_home',
  'phone_mobile',
  'phone_work'
];

let userFields = [
  'email',
  'is_active',
  'password',
  'reset_password_token',
  'is_deleted'
];

let userDetailFields = [
  'prefixname',
  'firstname',
  'middlename',
  'lastname',
  'suffixname',
  'phone_primary',
  'phone_home',
  'phone_mobile',
  'phone_work'
];

let accountFields = [
  'id',
  'user_id',
  'group_id',
  'account_type',
  'account_name',
  'account_type'];

/**
 * Retrieve one whole user.
 */
export function retrieveWholeUser(req, res, next) {
  const { user_id } = req.params;
  // retrieve user
  userUtils.retrieveWholeUser(user_id)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(filterUser(result));
      }
    })
    .catch(err => {
        next(err);
    });
}

/**
 * Query ICD by account_id.
 */
export function retrieveICDsbyAccountId(req, res, next) {
  const { account_id } = req.params;

  userUtils.retrieveICDsbyAccountIds([account_id])
    .then(result => {
      res.json({ account_id, icds: result });
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query ICD by user_id.
 */
export function retrieveICDsbyUserId(req, res, next) {
  const { user_id } = req.params;
  userUtils.retrieveICDsbyUserId(user_id)
    .then(result => {
      res.json({ user_id, icds: result });
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query users by device_id.
 */
export function retrieveUsersbyDeviceId(req, res, next) {
  const { device_id } = req.params;
  userUtils.retrieveUserbyDeviceId(device_id)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch whole user.
 */
export function patchWholeUser(req, res, next) {
  const { user_id } = req.params;

  // let checkedPassword = checkPassword(req.body.password);
  // if(!_.isEmpty(checkedPassword)) {
  //   next(checkedPassword);
  // } else {

  if(true) {
    // separate all fields
    let paramsUser = {};
    let paramsUserDetail = {};

    // user
    // NOTE: this approach DOES NOT WORK FOR A false BOOLEAN.
    for(let field_id in userFields) {
      let field_name = userFields[field_id];
      // do not patch undefined attribute, empty one should be remove.
      if(!_.isUndefined(req.body[field_name])) paramsUser[field_name] = req.body[field_name];
    }
    if("is_active" in req.body) {
      paramsUser["is_active"] = req.body["is_active"];
    }

    // user detail
    for(let field_id in userDetailFields) {
      let field_name = userDetailFields[field_id];
      // do not patch undefined attribute, empty one should be remove.
      if(!_.isUndefined(req.body[field_name])) paramsUserDetail[field_name] = req.body[field_name];
    }
    userUtils.patchWholeUser(user_id, paramsUser, paramsUserDetail)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Create one whole user.
 */
export function createWholeUser(req, res, next) {

  let paramsUser = {};
  let paramsUserDetail = {};
  for(let field_id in userFields) {
    let field_name = userFields[field_id];
    // do not create undefined or empty attribute
    if(!_.isUndefined(req.body[field_name]) && req.body[field_name] !== '') paramsUser[field_name] = req.body[field_name];
  }
  for(let field_id in userDetailFields) {
    let field_name = userDetailFields[field_id];
    // do not create undefined or empty attribute
    if(!_.isUndefined(req.body[field_name]) && req.body[field_name] != '') paramsUserDetail[field_name] = req.body[field_name];
  }
  userUtils.createWholeUser(paramsUser, paramsUserDetail)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create account by user_id.
 */
export function createNewAccount(req, res, next) {

  // create account
  userUtils.createNewAccount(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

export function removeWholeUser(req, res, next) {
  const { user_id } = req.params;

  userUtils.removeWholeUser(user_id)
    .then(result => {
      if(!result.user_id) {
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
 * Scan all whole user.
 */
export function scanWholeUser(req, res, next) {
  const { size, page } = req.query;

  elasticSearchUsers.scanAll(size, page)
    .then(result => {
      res.json(makeSearchResponse(result));
    })
    .catch(err => {
      next(err);
    });
}

export function searchUserByEmail(req, res, next) {
  const { email } = req.params;

  userUtils.searchUserByEmail(email)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveUserByGroup(req, res, next) {
  const { group_id } = req.params;
  const { size, page } = req.query;

  elasticSearchUsers.retrieveUserByGroup(group_id, size, page)
    .then(result => {
      res.json(makeSearchResponse(result));
    })
    .catch(err => {
      next(err);
    });
}

export function searchUserInGroup(req, res, next) {
  const { group_id } = req.params;
  const { match_string, size, page } = req.query;

  elasticSearchUsers.searchUserInGroup(group_id, match_string, size, page)
    .then(result => {
      res.json(makeSearchResponse(result));
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveUserICDByGroup(req, res, next) {
  const { group_id } = req.params;

  userUtils.retrieveUserICDByGroup(group_id)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

export function search(req, res, next) {
  const { match_string, size, page } = req.query;
  // match_string is necessary. Put required when validator active.

  elasticSearchUsers.search(match_string, size, page)
    .then(result => {
      res.json(makeSearchResponse(result));
    })
    .catch(err => {
      next(err);
    });
}
