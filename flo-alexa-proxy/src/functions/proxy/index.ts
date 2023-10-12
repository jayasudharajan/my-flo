import schema from './ping-schema';
import { handlerPath } from '@libs/handler-resolver';

const dir = handlerPath(__dirname);

const routes: any = {
  ping: {
    handler: `${dir}/handler.ping`,
    events: [
      {
        http: {
          method: 'get',
          path: '',
        }
      },
      {
        http: {
          method: 'post',
          path: 'ping',
        }
      },
    ]
  },

  relay: {
    handler: `${dir}/handler.relay`,
    events: [
      {
        http: {
          method: 'post',
          path: 'relay',
          request: {
            schema: {
              'application/json': schema
            }
          }
        }
      },
    ],
  },

  relay_proxy: {
    handler: `${dir}/handler.relay`,
    events: [
      {
        http: {
          method: 'post',
          path: 'relay/{proxy+}',
          request: {
            schema: {
              'application/json': schema
            }
          }
        }
      },
    ],
  },

  lambda: {
    handler: `${dir}/handler.relay`,
    events: [
      {
        http: {
          method: 'post',
          path: 'lambda',
          request: {
            schema: {
              'application/json': schema
            }
          }
        }
      },
    ],
  },

  lambda_proxy: {
    handler: `${dir}/handler.relay`,
    events: [
      {
        http: {
          method: 'post',
          path: 'lambda/{proxy+}',
          request: {
            schema: {
              'application/json': schema
            }
          }
        }
      },
    ],
  },

};

export default routes;
