const moment = require('moment');
const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes');
const EVENTS = util.EVENTS;

const updateICD = (id, timestamp, body, attempts = 2) => {
  
  return doForEachIndex(timestamp, index => 
    esClient.update({
      index,
      type: 'icd',
      id,
      retryOnConflict: 10,
      body
    })
    .catch(err => {
      if (err.status == 404 && attempts > 0) {
        const deferred = Promise.defer();

        setTimeout(() => {
          updateICD(id, timestamp, body, attempts - 1)
            .then(result => deferred.resolve(result))
            .catch(err => deferred.reject(err));
        }, (3 - attempts) * 250);

        return deferred.promise

      } else if (err.status == 404) {
        return Promise.resolve();
      } else {
        return Promise.reject(err);
      }
    })
  );
}

const removeICD = (id, timestamp) => new Promise((resolve, reject) => {
  
  return doForEachIndex(timestamp, index => 
    esClient.delete({ index, type: 'icd', id })
      .then(res => resolve(res))
      .catch(err => {
        if (err.status == 404) {
          resolve();
        } else {
          reject(err);
        }
      })
  );
});

function updateAlert(parent, id, timestamp, body) {

  return doForEachIndex(timestamp, index =>
    esClient.update({
      index,
      type: 'alert',
      parent,
      id,
      retryOnConflict: 2,
      body
    })
  );
}

function getIndices(timestamp) {
  return [
    util.getLogIndexName('activity-log', timestamp)
  ]
  .concat(
    moment(timestamp).daysInMonth() == moment(timestamp).date() ?
      [util.getLogIndexName('activity-log', moment(timestamp).add(1, 'month'))] :
      []
  )
  .concat(
    moment(timestamp).date() == 1 && moment(timestamp).subtract(1, 'month').toDate() >= new Date('2018-01-01T00:00:00.000Z') ?
      [util.getLogIndexName('activity-log', moment(timestamp).subtract(1, 'month'))] :
      []
  );
}

function doForEachIndex(timestamp, fn) {
  
  if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

  return Promise.all(
    getIndices(timestamp)
      .map(index => fn(index))
  );
}

module.exports = pubsub => {

  pubsub.subscribe('ICD', [EVENTS.INSERT, EVENTS.MODIFY], icd => {

    return joinICDToLocation(icd.location_id)
      .then(location => 
        Promise.all([
            location && retrieveAccount(location.account_id),
            location && joinLocationToUsers(location.location_id)
              .then(user_ids => 
                Promise.all(user_ids.map(user_id => retrieveUser(user_id)))
              ),
            location && retrieveAccountSubscription(location.account_id)
        ])
        .then(result => {
          const account = result[0];
          const users = result[1];
          const subscription = result[2];
          const doc = doctypes.createICD({ icd, location, account, users, subscription });

          return updateICD(icd.id, new Date().toISOString(), { doc, upsert: doc });
        })
      );
  });


  pubsub.subscribe('ICD', [EVENTS.REMOVE], icd => {
    return removeICD(icd.id, new Date().toISOString());
  });

  // pubsub.subscribe('Location', [EVENTS.INSERT, EVENTS.MODIFY], location => {
  //   return joinLocation(location.location_id)
  //     .then(icd_ids => Promise.all(
  //       icd_ids.map(icd_id => {
  //         const doc = doctypes.createICD({ location });

  //         return updateICD(icd_id, new Date().toISOString(), { doc, upsert: doc });
  //       })
  //     ));
  // });

  pubsub.subscribe('Account', [EVENTS.INSERT, EVENTS.MODIFY], account => {
    return joinAccount(account.id)
      .then(icd_ids => Promise.all(
        icd_ids.map(icd_id => {
          const doc = doctypes.createICD({ account });

          return updateICD(icd_id, new Date().toISOString(), { doc, upsert: doc });
        })
      ));
  });

  // pubsub.subscribe('User', [EVENTS.INSERT, EVENTS.MODIFY], user => {
  //   return joinUser(user.id)
  //     .then(icd_ids => Promise.all(
  //       icd_ids.map(icd_id => {
  //         const userData = { user_id: user.id, email: user.email };
  //         const script = esUtil.mergeArrayItem('users', userData, 'user_id');
  //         const body = {
  //           script,
  //           upsert: {
  //             id: icd_id,
  //             users: [userData]
  //           }
  //         };

  //         return updateICD(icd_id, new Date().toISOString(), body);
  //       })
  //     ));
  // });

  // pubsub.subscribe('User', [EVENTS.REMOVE], user => {
  //   return joinUser(user.id)
  //     .then(icd_ids => Promise.all(
  //       icd_ids.map(icd_id => {
  //         const script = esUtil.removeArrayItem('users', { user_id: user.id }, 'user_id');
  //         const body = {
  //           script
  //         };

  //         return updateICD(icd_id, new Date().toISOString(), body);
  //       })
  //     ));
  // });

  // pubsub.subscribe('UserDetail', [EVENTS.INSERT, EVENTS.MODIFY], userDetail => {
  //   return joinUser(userDetail.user_id)
  //     .then(icd_ids => Promise.all(
  //       icd_ids.map(icd_id => {
  //         const userData = { 
  //           user_id: userDetail.user_id, 
  //           firstname: userDetail.firstname, 
  //           lastname: userDetail.lastname 
  //         };
  //         const script = esUtil.mergeArrayItem('users', userData, 'user_id');
  //         const body = {
  //           script,
  //           upsert: {
  //             id: icd_id,
  //             users: [userData]
  //           }
  //         };

  //         return updateICD(icd_id, new Date().toISOString(), body);
  //       })
  //     ));
  // });

  // pubsub.subscribe('UserDetail', [EVENTS.REMOVE], userDetail => {
  //   return joinUser(userDetail.user_id)
  //     .then(icd_ids => Promise.all(
  //       icd_ids.map(icd_id => {
  //         const script = esUtil.removeArrayItem('users', { user_id: userDetail.user_id }, 'user_id');
  //         const body = {
  //           script
  //         };

  //         return updateICD(icd_id, new Date().toISOString(), body);
  //       })
  //     ))
  //     .catch(err => {
  //       if (err.status == 404) {
  //         return Promise.resolve();
  //       }

  //       return Promise.reject(err);
  //     });
  // });

  pubsub.subscribe('OnboardingLog', [EVENTS.INSERT, EVENTS.MODIFY], onboardingLog => {

    if (!Date.parse(onboardingLog.created_at)) {
      return Promise.resolve();
    }
    
    const icdId = onboardingLog.icd_id;
    const onboardingData = { created_at: onboardingLog.created_at, event: onboardingLog.event };
    const script = esUtil.insertArrayItem('onboarding', onboardingData);
    const body = {
      script,
      upsert: {
        id: icdId,
        onboarding: [onboardingData]
      }
    };

    return updateICD(icdId, onboardingData.created_at || new Date().toISOString(), body);
  });

  pubsub.subscribe('AccountSubscription', [EVENTS.INSERT, EVENTS.MODIFY], accountSubscription => {
    const account_id = accountSubscription.account_id;
    const subscriptionData = util.omit(accountSubscription, ['account_id']);
    const inline = 
      'if (ctx._source.containsKey("account")) { ctx._source.account.subscription = params.subscription; } ' +
      'else { ctx._source.account = params.account; }';
    const script = {
      inline,
      lang: 'painless',
      params: {
        subscription: subscriptionData,
        account: {
          account_id,
          subscription: subscriptionData
        }
      }
    };

    const doc = { 
      account: {
        account_id,
        subscription: subscriptionData
      }
    };

    return joinAccount(account_id)
      .then(icdIds => Promise.all(
        icdIds.map(icdId => updateICD(icdId, new Date().toISOString(), { 
          doc, 
          upsert: Object.assign(
            { id: icdId },
            doc
          ) 
        }))
      ));
  });

  pubsub.subscribe('AccountSubscription', [EVENTS.REMOVE], accountSubscription => {
    const account_id = accountSubscription.account_id;

    return esClient.updateByQuery({
      index: util.getLogIndexName('activity-log', new Date().toISOString()),
      type: 'icd',
      body: {
        query: {
          bool: {
            filter: {
              term: {
                'account.account_id': account_id
              }
            }
          }
        },
        script: {
          inline: 'if (ctx._source.containsKey("account")) { ctx._source.account.remove("subscription"); } ',
          lang: 'painless'
        }
      }
    });
  });

  pubsub.subscribe('UserLocationRole', [EVENTS.INSERT], userLocationRole => {
    return Promise.all([
      retrieveUser(userLocationRole.user_id),
      joinLocation(userLocationRole.location_id)
    ])
    .then(result => {
      const userData = {
        user_id: result[0].user_id,
        email: result[0].email,
        firstname: result[0].firstname,
        lastname: result[0].lastname
      };
      const icdIds = result[1];
      const script = esUtil.mergeArrayItem('users', userData, 'user_id');

      return Promise.all(
        icdIds.map(icdId => updateICD(icdId, new Date().toISOString(), {
          script,
          upsert: {
            id: icdId,
            users: [userData]
          }
        }))
      );
    });
  });

  pubsub.subscribe('AlarmNotificationDeliveryFilter', [EVENTS.INSERT, EVENTS.MODIFY], alarmNotificationDeliveryFilter => {

    if (!alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id) {
      return Promise.resolve();
    }
    
    const icdId = alarmNotificationDeliveryFilter.icd_id;

    return updateAlert(
      icdId, 
      alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id,
      alarmNotificationDeliveryFilter.incident_time,
      {
        doc: alarmNotificationDeliveryFilter,
        upsert: alarmNotificationDeliveryFilter
      }
    );
  });

};

function joinICDToLocation(location_id) {
  return dynamoClient.query({
    TableName: util.getTableName('Location'),
    IndexName: 'LocationIdIndex',
    KeyConditionExpression: '#location_id = :location_id',
    ExpressionAttributeNames: {
      '#location_id': 'location_id'
    },
    ExpressionAttributeValues: {
      ':location_id': location_id
    }
  })
  .promise()
  .then(result => result.Items[0]);
}

function retrieveAccount(account_id) {
  return dynamoClient.get({
    TableName: util.getTableName('Account'),
    Key: {
      id: account_id
    }
  })
  .promise()
  .then(result => result.Item);
}

function joinLocation(location_id) {
  return dynamoClient.query({
    TableName: util.getTableName('ICD'),
    IndexName: 'LocationIdIndex',
    KeyConditionExpression: '#location_id = :location_id',
    ExpressionAttributeNames: {
      '#location_id': 'location_id'
    },
    ExpressionAttributeValues: {
      ':location_id': location_id
    }
  })
  .promise()
  .then(result => result.Items.map(item => item.id));
}

function joinAccount(account_id) {
  return dynamoClient.query({
    TableName: util.getTableName('Location'),
    KeyConditionExpression: '#account_id = :account_id',
    ExpressionAttributeNames: {
      '#account_id': 'account_id'
    },
    ExpressionAttributeValues: {
      ':account_id': account_id
    }
  })
  .promise()
  .then(result => Promise.all(
    result.Items.map(item => joinLocation(item.location_id))
  ))
  .then(results => 
    results.reduce((acc, icd_ids) => acc.concat(icd_ids), [])
  );
}

function joinUser(user_id) {
  return dynamoClient.query({
    TableName: util.getTableName('UserLocationRole'),
    KeyConditionExpression: '#user_id = :user_id',
    ExpressionAttributeNames: {
      '#user_id': 'user_id'
    },
    ExpressionAttributeValues: {
      ':user_id': user_id
    }
  })
  .promise()
  .then(result =>
    Promise.all( 
      (result.Items || []).map(userLocationRole => 
        dynamoClient.query({
          TableName: util.getTableName('ICD'),
          IndexName: 'LocationIdIndex',
          KeyConditionExpression: '#location_id = :location_id',
          ExpressionAttributeNames: {
            '#location_id': 'location_id'
          },
          ExpressionAttributeValues: {
            ':location_id': userLocationRole.location_id
          }
        })
        .promise()
      )
    )
  )
  .then(results => 
      results
        .reduce((acc, result) => acc.concat(result.Items || []), [])
        .map(icd => icd.id)
  );
}

function joinLocationToUsers(location_id) {
  return dynamoClient.query({
    TableName: util.getTableName('UserLocationRole'),
    IndexName: 'LocationIdIndex',
    KeyConditionExpression: '#location_id = :location_id',
    ExpressionAttributeNames: {
      '#location_id': 'location_id'
    },
    ExpressionAttributeValues: {
      ':location_id': location_id
    }
  })
  .promise()
  .then(result => (result.Items || []).map(userLocationRole => userLocationRole.user_id));
}

function retrieveUser(user_id) {
  return Promise.all([
    dynamoClient.get({
      TableName: util.getTableName('User'),
      Key: {
        id: user_id
      }
    })
    .promise()
    .then(result => result.Item || {}),
    dynamoClient.get({
      TableName: util.getTableName('UserDetail'),
      Key: {
        user_id
      }
    })
    .promise()
    .then(result => result.Item || {})
  ])
  .then(result => ({
    user_id: result[0].id || result[1].user_id,
    firstname: result[1].firstname,
    lastname: result[1].lastname,
    email: result[0].email
  }));
}

function retrieveAccountSubscription(account_id) {
  return dynamoClient.get({
    TableName: util.getTableName('AccountSubscription'),
    Key: {
      account_id: account_id
    }
  })
  .promise()
  .then(result => result.Item || {});
}