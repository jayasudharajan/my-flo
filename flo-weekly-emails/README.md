# flo-weekly-emails

Sends weekly emails to customers.
SEE: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/1061421094/Weekly+Email+Service

### Initialize Project Files

After creating the new project, in Terminal (macOS) run `runonce.macos.sh`

It will ask for the name of the project to:
- rename all placeholders
- enable gitlab cicd
- update k8s scripts

You can delete all runonce.* files after that

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
