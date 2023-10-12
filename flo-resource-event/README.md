# flo-resource-event

Template project for Golang Services using Gin framework for API: https://github.com/gin-gonic/gin

## Initialize Project Files

After creating the new project, in Terminal (macOS) run `runonce.sh`

It will ask for the name of the project to:

- rename all placeholders
- enable gitlab cicd
- update k8s scripts

You can delete all runonce.* files after that: `rm runonce.*`

### Kafka

To run/debug locally, librdkakfa is required.
https://docs.confluent.io/current/clients/librdkafka/md_INTRODUCTION.html

On macOS:

- `brew install pkg-config`
- `brew install librdkafka`

ENVIRONMENT may need the following:

- `PKG_CONFIG=/usr/local/bin/pkg-config`

### GO runtime

https://golang.org

On macOS:

- `brew install go`
- Install XCode command line utilities

######## Rest Api

######## Create resource event

curl --location --request POST 'http://localhost:8080/event' \
--header 'Content-Type: application/json' \
--data-raw '{
       "date": "2021-02-01T18:28:58Z",
       "accountId": "0086a36b-f16f-4183-8fdd-69ef8c065b3c",
       "resourceType": "device",
       "resourceAction": "updated",
       "resourceName": "device01",
       "resourceId": "92666d8c-2e09-422f-99a5-fcaed46dd7a6",
       "userName": "Luciano",
       "userId": "a44cd81f-3c11-4e8f-87c5-a14d6a7e7d06",
       "ipAddress": "192.168.0.0",
       "clientId": "266399cf-f0bd-47c2-80bb-e514766f51d8",
       "userAgent": "android",
       "eventData": "{}"
}'

######## Get all resource Events

curl --location --request GET 'http://localhost:8080/event?accountId=%220086a36b-f16f-4183-8fdd-69ef8c065b3c%22'
