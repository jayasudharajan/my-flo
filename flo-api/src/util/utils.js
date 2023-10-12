import _ from 'lodash';
var fs = require('fs');
var config = require('../config/config');

// Basic collection (set) +/-.
export function addSetItem(items, item) {
  if(_.indexOf(items, item) < 0) {
    items.push(item);
  }
}

export function removeSetItem(items, item) {
  if(_.indexOf(items, item) > -1) {
    _.pull(items, item);
  }
}

export function LookUpPurchasedICD(id, code) {
    if (id == '6e0d855f-ba44-4062-9523-71578fa89f98' && code == 'CrLaDxoDIGTz') {
        return {
                            did: 'f87aef0000ba',
                            apName:'mlb WiFi',
                            apPassword:'1234567890',
                            icdLoginName: 'mlb',
                            icdLoginPassword: 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
                            serverCert: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlEc1RDQ0FwbWdBd0lCQWdJRWJQS3FqREFOQmdrcWhraUc5dzBCQVFzRkFEQ0JpREVMTUFrR0ExVUVCaE1DVlZNeEN6QUpCZ05WDQpCQWdUQWtOQk1SUXdFZ1lEVlFRSEV3dE1iM01nUVc1blpXeGxjekVaTUJjR0ExVUVDaE1RUm14dklGUmxZMmh1YjJ4dloybGxjekVZDQpNQllHQTFVRUN4TVBSbXh2SUVWdVoybHVaV1Z5YVc1bk1TRXdId1lEVlFRREV4aHRjWFIwTG1ac2IzUmxZMmh1YjJ4dloybGxjeTVqDQpiMjB3SGhjTk1UWXdNakUyTWpNMU1qQXhXaGNOTVRjd01qRXdNak0xTWpBeFdqQ0JpREVMTUFrR0ExVUVCaE1DVlZNeEN6QUpCZ05WDQpCQWdUQWtOQk1SUXdFZ1lEVlFRSEV3dE1iM01nUVc1blpXeGxjekVaTUJjR0ExVUVDaE1RUm14dklGUmxZMmh1YjJ4dloybGxjekVZDQpNQllHQTFVRUN4TVBSbXh2SUVWdVoybHVaV1Z5YVc1bk1TRXdId1lEVlFRREV4aHRjWFIwTG1ac2IzUmxZMmh1YjJ4dloybGxjeTVqDQpiMjB3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRQ3M2ZnVQK2czNks3RFhJRWk3WFJnTHkvRlVHR2VMDQoralEzTlhuMEhtOVRTZFkrTTlGNnZuVzJWTlNjZ29SYnR1LzUwdVRJZkJTTHpyaXNHeEI3UG9aR1l4TWswWkZNZUVhaWNFcmVDWm01DQpQWHNKYlF1azE1SjZ0bXFOYzc1T20zb2ZVdzRDK1V5R3BRQVJxNU5jQUJOSHlvVEJkT0dROFdnNzBsNWVUZUtER0R0Sjg1bFU4N0NFDQpNTmo2TlFudWVHZUloVEFMUW5XcnkwOHNRS2dFcHBVZmROa2JRQmtUckNxSTU0QnRQOFNKR2puTDFOQlVJblBBYy93ZUxDcUdoZVpODQovaDBlRWdWeGxGRVlVOXFuSEtLQlJ5VG1HdnpTS3VzbFNQZnlYdWF0OHJUSEpWS3lYUVg1Nmhtb1BDYXA1cmNrQmhmdStGL092OVIyDQp5cUhYNGd1OUFnTUJBQUdqSVRBZk1CMEdBMVVkRGdRV0JCU3ZFdFpYUjR5d2JCUWNKdGNxRVNxQnJJRmJLekFOQmdrcWhraUc5dzBCDQpBUXNGQUFPQ0FRRUFGQi9HWTlVQkhBUWhTWCtVSUxWRlM1NVdjbzdiYk5abk5vZktjQ3lGSjlsY2lIV1pJRDg3NmFMdXNBaXhLMkduDQpubWVNWUs4am5nYWI1dS85TEVPZVlHUW5vV0hHRTJNMGlIR0VMMklTTWxGR0Irc2hadHp5V3haYlorTEdsZ2RBWnhNQ3lOSTFMdlNEDQpiMlk3RmhSOHVQUzRlYnkzZlJMcm80cWxIU1RwZWI3QlpJV24wYzkzVGFYdzV2ZXk3WC96ZGxZbXc2SUZwY1NFOUlqSDgyZzBUb3o1DQpCbzFWbHFTS3YrUFZKSDZ4YlJlWkc1aE5nUm5SaVZWOHVEVHhzU3V1dlRubFd1a3BFUm9henVPUW4xUERxcVB3REd1ZlhWYXJROHdZDQoybnRHNlk2VlFiT0MzNkdOQW8rcUxhRWVUcUxRUmQzUVU0MG5HdnB3bUtYV1N1dmJlUT09DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t",
                            clientCert: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlFMERDQ0E3aWdBd0lCQWdJSkFKaHhKdUZmdTIvb01BMEdDU3FHU0liM0RRRUJCUVVBTUlHZ01Rc3dDUVlEDQpWUVFHRXdKVlV6RUxNQWtHQTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJibWRsYkdWek1Sa3dGd1lEDQpWUVFLRXhCR2JHOGdWR1ZqYUc1dmJHOW5hV1Z6TVJRd0VnWURWUVFMRXd0RmJtZHBibVZsY21sdVp6RTlNRHNHDQpBMVVFQXhRMFpqZzZOMkU2WldZNk1EQTZNREE2TTJWOGMyTnBiR2x1WjI5Zk1Yd3dPRFptWmpWaE1pMHdOREUwDQpMVFEzTldZdE9UY3hOakFlRncweE5qQXlNVGN3TnpNeU1EbGFGdzB4TmpBek1UZ3dOek15TURsYU1JR2dNUXN3DQpDUVlEVlFRR0V3SlZVekVMTUFrR0ExVUVDQk1DUTBFeEZEQVNCZ05WQkFjVEMweHZjeUJCYm1kbGJHVnpNUmt3DQpGd1lEVlFRS0V4QkdiRzhnVkdWamFHNXZiRzluYVdWek1SUXdFZ1lEVlFRTEV3dEZibWRwYm1WbGNtbHVaekU5DQpNRHNHQTFVRUF4UTBaamc2TjJFNlpXWTZNREE2TURBNk0yVjhjMk5wYkdsdVoyOWZNWHd3T0RabVpqVmhNaTB3DQpOREUwTFRRM05XWXRPVGN4TmpDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTW9EDQovNlZidXlnSU1HQy9hbHpuQnFCNXNURWNUNmVtVHZvSExEM0NZMUN6OVFzeHpHQkUrVFVQVitCU20vNWJLZlJKDQowVE9xVEdVWkc1bEJJOWN1THhJSk80NXdSSlkrQU9zVXJhNjJVdHppZXBCQXVJMmYxWEpFTkRKdzJrOUNMYkdYDQpOem9LVUxzKzZFWHFBeFF3bk1ETWtlOXhMTm5hanZjZ2YvUFBKanJQTk5GVkJQZFY4ZnRUNHRtcW5UL1EvWlMvDQpDNVQwTHBuaXRlZS9kWitCdlYwSWZHVUVmb3RNVjIwcGNMOTJUZHA2MDAwcW9QVlFkMmFvN05CclhtUEswTGZEDQpjd21qNmNaV0xZeEY1ZWREYktia2JpWjV3RmRQTDZSMnBvVHRhRlhFWDhyRUlhK1NQVWYyRDRSQTczaU9ScUIwDQpJS05vNXNycTRZdHVxZWJiZFFjQ0F3RUFBYU9DQVFrd2dnRUZNQjBHQTFVZERnUVdCQlJXTzBuNFhUVFMvaVZLDQpBWjNOMXFiQnJhTDc3ekNCMVFZRFZSMGpCSUhOTUlIS2dCUldPMG40WFRUUy9pVktBWjNOMXFiQnJhTDc3NkdCDQpwcVNCb3pDQm9ERUxNQWtHQTFVRUJoTUNWVk14Q3pBSkJnTlZCQWdUQWtOQk1SUXdFZ1lEVlFRSEV3dE1iM01nDQpRVzVuWld4bGN6RVpNQmNHQTFVRUNoTVFSbXh2SUZSbFkyaHViMnh2WjJsbGN6RVVNQklHQTFVRUN4TUxSVzVuDQphVzVsWlhKcGJtY3hQVEE3QmdOVkJBTVVOR1k0T2pkaE9tVm1PakF3T2pBd09qTmxmSE5qYVd4cGJtZHZYekY4DQpNRGcyWm1ZMVlUSXRNRFF4TkMwME56Vm1MVGszTVRhQ0NRQ1ljU2JoWDd0djZEQU1CZ05WSFJNRUJUQURBUUgvDQpNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0SUJBUUJabU13SEJPY3RGMnQzalRweWk2STlaTHlIMy8rcGNEc3d2c0JmDQpoaEx6MnZ0NWFkeTdOK3RTTzVkTEMyNytQdnZUUkMxVW9SNG1TNXdwRmo1ampzRUlacGFQMHFZL1JUOXB5RkxEDQpScjU4ODlYU2JneVk5L2dqODB1Uk9vN0FoSldUUkh3cHBUc2NnQ2p4QWFhOUJVWjZ6aFEweTZaUlVVdk5XYnFwDQpGMlRMdUROb3VUZVRZQWViVlJSd2RJMmVhS2dGVklrRVV6eWVkZzQ3TWc4QnlWbWhqZG8yRWhkRDVMQjFoM0pkDQpNc1dzWlc2c0h0WEJXVlFwMjRyNnFqL3lIVVQ5UFRROE1PQkZpNHNyTThWaVNoTWlZVU1JUUtML2IvRTcvK3F5DQo4eGZBcUk3M053MVpZOEtoZWsrRXdXU1E5eXkwQ1VSdk9ybzJxMllIYWVjcVYzYXANCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0=",
                            clientKey: "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ0KTUlJRW93SUJBQUtDQVFFQXlnUC9wVnU3S0Fnd1lMOXFYT2NHb0hteE1SeFBwNlpPK2djc1BjSmpVTFAxQ3pITQ0KWUVUNU5ROVg0RktiL2xzcDlFblJNNnBNWlJrYm1VRWoxeTR2RWdrN2puQkVsajRBNnhTdHJyWlMzT0o2a0VDNA0KalovVmNrUTBNbkRhVDBJdHNaYzNPZ3BRdXo3b1Jlb0RGRENjd015UjczRXMyZHFPOXlCLzg4OG1PczgwMFZVRQ0KOTFYeCsxUGkyYXFkUDlEOWxMOExsUFF1bWVLMTU3OTFuNEc5WFFoOFpRUitpMHhYYlNsd3YzWk4ybnJUVFNxZw0KOVZCM1pxanMwR3RlWThyUXQ4TnpDYVBweGxZdGpFWGw1ME5zcHVSdUpubkFWMDh2cEhhbWhPMW9WY1JmeXNRaA0KcjVJOVIvWVBoRUR2ZUk1R29IUWdvMmpteXVyaGkyNnA1dHQxQndJREFRQUJBb0lCQUdLc1AxTjZrZGtFM3ZSeQ0KcXJaRUZlV09hekVzdmUrS2VTc0JFK2Y2cWQ0Q2VGK0diR2hkYUVnMWZWdlJuZVpJaXg2S2E4ZkxsOU1OeDRBOA0KNUErM3ZFQVlDR0lUamp6QWZseFUxbHp2SzF3K3QxVDhkK2lkT0htK3ZLd2ltVTk3YUt4RXl6SHJWZkdQMFk1TQ0KdGtKSFdGbUgwb1JkQ0daRXJlNGhqcjM4NFpSNVFNeDkrNmJITkFMUEcvS2FDbE11VmRuRFlWdUg4Y1pnUm5CSQ0KL2lHSnBlNldIV3VLTFhzYmhKL3BDSGppVVhKd3ZZUUpZbXErQ0l6YnNtU1pjZThpMjBwUExoZDBXaWlOYlJydQ0KOHd4ZUVZQVZxS2V2NGVGdFZ1KzhoSG9ucDJ2b1VQR3NhSnlSSHFnbEpmbmNYdDFrNjgrQzhDNndwbmFjRS83NQ0KSi9Nc0ZERUNnWUVBN3IrWlRCUzU2K1V2QmdNSVNFUFBhRDljM1dVRjU0UUg3N3p4QXpxVmFmdzJWVktyTnFIag0KSVB4T3owaERINTNFWU5KOUpZYUp2UDhLMGlGb2l1ZWk1NTZ1ckRxVi9YQTJDZjVXWE8vN0dsMXplOEZmVXRKcw0KZE5ReWRXMFU4QWp5Z1hSZmxhalpkOFAvK3JMRGFDcWkwRC8zZDd6ckpEMkJjVzJsbm1Bb1A3a0NnWUVBMkp6cA0KUS9GOFN0akZxbEowcE81Zm80VVYxR2NlRFFHN3JKeU1RaDViYjR6M0ljR2FqZWJEajB0OFVPc0FkWnRIVjN0Mg0KVWsxRnJxSTRMMjBYUzNpWlNzcURMT21pT2pDLzdUdjJvd0NoWHpPQzcwd1hicXNRRWowblAzMm1TRllJNUFvaQ0KMnZPSjI1NGxVLzhjcE45QmFrd3ZGc0RwMjRxdU01T2x5U2VFT3I4Q2dZQnFQeS9NVU1qd2RweDNrMi9qSVBJeg0KRlVlUmF2eTJxK1lRUlVnSVJORHJTb2N2YjB1c1Uxek5lQnJtV2VVdE03dUp6d0pNYWRQd0hKdkhLWURwbCszQw0KSDdiaUJHeHRUYnR1dFJYZjVCZ2VBb3A2LzNJWlhIVlJoSUUwQ3FndnJmdWxxcEZDKzlKVFh4RVNrdTBzOVJSaA0Ka3FYaFRseGlVMURBbHFnR2xBbzFXUUtCZ0NIUDdJR1VrbWhFaWlaYUZLY2lKbitwNkl4dFJEMlhoYW9lRGE3TQ0KZWsxaFhicEJORlR1THB5UmxlZ3pwckMwK2wvbmY4SzlHU0YzWlBuU040NnFWcE5jSlRtL2huazYzdHF6UDM2Vw0KUEpwVnVoeU1iaVB5UStIMDljbHRYYVZ3K0paUUZyekN3MFFxM1h6TkY3V011L05SelEvcU1SYjZBTk5BT3VLNQ0KYm1TVkFvR0JBS2Z1UjY3a2d4OVEzTThSQ0pQMTZMVTdRN3h1ZGdVTlhMUGp2aUtjZDNTUTM3S0d0WElYNjk4Qw0KdXMvQWlPSWQ5ejFidGlKR3cvOXJhNmgxYlhITlZNaExxamFUZ1RuUUk4b1NOSUx5Mi9vSmVNTzYrR1RZRDBEYw0KY0Q5S1RQZXlaa01NTFE0NEFwL3Vsdnl2YThSaXZ1UEJXbXhZYVNHaGNOVTQ5c3MwR01MQg0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0="
                            }
    }
    return null;
}

function pathExist(path) {
    try {
        fs.accessSync(path, fs.F_OK);
        return true;
    } catch (e) {
        return false;
    }
}

function readCertFile(filename, callback) {
    fs.readFile(filename, function (err, data) {
        if (err) {
            callback(err);
            return;
        }
        try {
            callback(null, JSON.parse(data));
        } catch (exception) {
            callback(exception);
        }
    });
}

/**
 * NOTE: Gets the FIRST account_id found.
 */
export function extractAccountInfo(user) {

  if('accounts' in user) {
    if(user.accounts.length) {
      return user.accounts[0]
    }
  }
  return "";
  //throw Error("Unable to find account_id.");
}

/**
 * NOTE: Gets the FIRST location_id found.
 */
export function extractLocationInfo(user) {

  if('accounts' in user) {
    if(user.locations.length) {
      return user.locations[0]
    }
  }
  return "";
  //throw Error("Unable to find location_id.");
}

export function stripCollection(items, attribute) {
  for(let item of items) {
    delete item[attribute];
  }
  return items;
}

/**
 * NOTE: Validates a 12 characters MACID. i.e. 8cc7aa0280dc
 * regex.test is faster than string.match for matching.
 */
export function isValidDeviceId(str) {
    var re = /^(([a-fA-F0-9]){12})+$/g;
    return re.test(str);
}

/**
 * Get fixed table namea
 */
export function getFixedTableName(originalTableName) {
    return config.aws.dynamodb.prefix + originalTableName;
}

/**
 * Returns environment shorthand.
 * TODO: switch to another config param rather than AWS prefix(?)
 */
export function getShortEnv(originalTableName) {
  return _.replace(config.aws.dynamodb.prefix, '_', '');
}

/**
 * Check if password strong enough
 * length 8 - 32
 * contain at least one Upper letter
 * contain at least one lower letter
 * contain at least one number
 */
export function checkPassword(password) {
  if(password === null) return { status: 400, message: 'Password should not be null.' };
  if(_.isUndefined(password)) return { status: 400, message: 'Password required.' };
  if(password.length < 8 || password > 32) return { status: 400, message: 'Password length should be 8 ~ 32.' };
  if(!_.isArray(password.match(/[A-Z]/))) return { status: 400, message: 'Password should contain an Upper letter.' };
  if(!_.isArray(password.match(/[a-z]/))) return { status: 400, message: 'Password should contain a lower letter.' };
  if(!_.isArray(password.match(/[0-9]/))) return { status: 400, message: 'Password should contain number.' };
  return {};
}
