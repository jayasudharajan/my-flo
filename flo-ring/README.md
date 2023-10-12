# flo-ring service

Ring integration with our Flo Water Shutoff Device

## Initialize Project Files

Should compile with VsCode: Shift + Command + B

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
