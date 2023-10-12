# flo-golang-gin-api

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
