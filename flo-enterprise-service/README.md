# flo-enterprise-service




### Kafka

To run/debug locally, librdkakfa is required.
https://docs.confluent.io/current/clients/librdkafka/md_INTRODUCTION.html

On macOS:

- `brew install pkg-config`
- `brew install librdkafka`

ENVIRONMENT may need the following:

- `PKG_CONFIG=/usr/local/bin/pkg-config`

## Access the service API
You have to be on VPN to reach the service
  
DEV base URL

https://flo-enterprise-service.flocloud.co

PROD base URL

https://flo-enterprise-service.flosecurecloud.com

### GO runtime

https://golang.org

On macOS:

- `brew install go`
- Install XCode command line utilities
