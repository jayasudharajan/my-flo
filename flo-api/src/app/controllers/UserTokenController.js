import _ from 'lodash';
import UserTokenTable from '../models/UserTokenTable';
import { errorType } from '../../config/constants';
let UserToken = new UserTokenTable();


export function retrieveOwn(req, res, next) {
  const { timestamp: time_issued, user: { user_id } } = req.decoded_token;

  return UserToken.retrieve({ user_id, time_issued })
    .then(({ Item }) => {
      if (!Item) {
        throw errorType.USER_TOKEN_NOT_FOUND;
      }

      return res.json(Item);
    })
    .catch(err => next(err));
}

// /**
//  * Retrieve one UserToken.
//  */
// export function retrieve(req, res, next) {

//   const { user_id, time_issued } = req.params;
//   let keys = { user_id, time_issued };

//   UserToken.retrieve(keys)
//     .then(result => {
//       if(_.isEmpty(result)) {
//         res.status(404).send({ error: true, message: "Item not found." });
//       } else {
//         res.json(result.Item);
//       }
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Create one UserToken.
//  */
// export function create(req, res, next) {

//   UserToken.create(req.body)
//     .then(result => {
//       res.json(result);
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Update one item.  (replace)
//  */
// export function update(req, res, next) {

//   const { user_id, time_issued } = req.params;

//   // Add url keys into request body.
//   req.body.user_id = user_id;
//   req.body.time_issued = time_issued;

//   UserToken.update(req.body)
//     .then(result => {
//       res.json(result);
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Patch one UserToken.  Use this to update individual fields.
//  */
// export function patch(req, res, next) {

//   const { user_id, time_issued } = req.params;
//   let keys = { user_id, time_issued };

//   UserToken.patch(keys, req.body)
//     .then(result => {
//       res.json(result);
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Delete one UserToken.
//  */
// export function remove(req, res, next) {

//   const { user_id, time_issued } = req.params;
//   let keys = { user_id, time_issued };

//   UserToken.remove(keys)
//     .then(result => {
//       if(!result) {
//         res.status(404).send({ error: true, message: "Item not found." });
//       } else {
//         res.json(result);
//       }
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Archive ('delete') one UserToken.
//  */
// export function archive(req, res, next) {

//   const { user_id, time_issued } = req.params;
//   let keys = { user_id, time_issued };

//   UserToken.archive(keys)
//     .then(result => {
//       if(_.isEmpty(result)) {
//         res.status(404).send({ error: true, message: "Item not found." });
//       } else {
//         // Returns: { Attributes: { is_deleted: true } }
//         res.json(result);
//       }
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Simple Table scan to retrieve multiple records.
//  */
// export function scan(req, res, next) {

//   UserToken.scanAll()
//     .then(result => {
//       res.json(result);
//     })
//     .catch(err => {
//       next(err);
//     });
// }

// /**
//  * Query set UserToken with same hashkey.
//  */
// export function retrieveByUserId(req, res, next) {

//   const { user_id } = req.params;
//   UserToken.retrieveByUserId({ user_id })
//     .then(result => {
//       res.json(result.Items);
//     })
//     .catch(err => {
//       next(err);
//     });
// }
