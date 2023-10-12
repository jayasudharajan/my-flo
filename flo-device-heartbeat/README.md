# flo-device-heartbeat

Manages device online/offline state in redis, postgres, and firestore. Works by listening to Kafka messages on multiple topics indicating communication from device to cloud. Handles devices that are stale, which are devices that disconnected but did not produce disconnect message, by setting them offline after an hour.

Batches are set to write data ever 10 seconds. If the current state is the same as last known, no data is written to data sources. Every 15 minutes, current state is written to the data sources regardless of previous state.

API endpoints can be used to get the state and set the state, this can be done at high volume. Response comes from Redis.

Debug endpoint is meant for low volume debug/admin purposes. There is cost associated due to requests from Google Firestore.

### Environments
- Dev: `https://flo-device-heartbeat.flocloud.co/`
- Prod: `https://flo-device-heartbeat.flosecurecloud.com/`


### API Endpoints

- `GET /ping`
- `GET /debug/{mac}`
  - Expensive
  - Debug/Admin Use Only
- `GET /state/{mac}`
  - Cheap - Comes from Redis
  - Can be used by clients
- `POST /state`
  - Admin clients should use `force=true`
  - High use clients should not use `force=true`

```
POST /state 
{
  "force": true|false,
  "macAddress": "74e182167758",
  "isConnectd": false,
}

or

POST /state 
{
  "force": true|false,
  "items": [
    {
      "macAddress": "abcd12340000",
      "isConnected": true
    },
    {
      "macAddress": "00001234abcd",
      "isConnected": false
    }
  ]
}
```

### External resources required

- Postgresql ( Device Service )
- FireWriter ( internal service ) https://flo-firewriter.flosecurecloud.com
- Redis
- Kafka