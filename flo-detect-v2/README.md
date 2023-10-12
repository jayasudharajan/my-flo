# Flo Detect version 2

Consumes device fixture detectections from Kafka and stores in the DB.

Provides reports and aggregates per device

Swagger Docs: /docs

### Kafka
To run/debug locally, librdkakfa is required.
https://docs.confluent.io/current/clients/librdkafka/md_INTRODUCTION.html

On macOS:
- `brew install pkg-config`
- `brew install librdkafka`

### GO runtime
https://golang.org

On macOS:
- `brew install go`
- Install XCode command line utilities
