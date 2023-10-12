# FLO Device Service

[![Build Status](https://gitlab.com/flotechnologies/flo-firewriter/badges/master/build.svg)](https://gitlab.com/flotechnologies/flo-firewriter/commits/master) [![Coverage Report](https://gitlab.com/flotechnologies/flo-firewriter/badges/master/coverage.svg)](https://gitlab.com/flotechnologies/flo-firewriter/commits/master) [![Go Report Card](https://goreportcard.com/badge/gitlab.com/flotechnologies/flo-firewriter)](https://goreportcard.com/report/gitlab.com/flotechnologies/flo-firewriter)

# Summary
This service sole responsibility is to get device telemetry data from mqtt topic and store it in Firestore.
Currently all the devices are sending telemetry data every second. This service has been tested with 4.5K devices
being online, therefore 4.5K msg/sec. 

Gotchas: 
- mqtt subscriber loses connection and needs to be restarted about every 3-5 min, it has been achieved
programmatically with watchdog as well as goroutine count on /ping endpoint with k8s liveliness probe
- the service is CPU hungry, for the messages rate mentioned above it can spawn up to 45 goroutines (Firestore
connector scales horizontally with each subsequent increase of batch writes, it's responsible for great portion of
total goroutines number), firehose service stabilizes within first 10 mins of being online and runs about 20-25
goroutines.

The service has substantial amount of logging. If there is need of troubleshooting, enable DEBUG level (it's value 1
for LOGS_LEVEL env var).

## what you need on dev:

### Mac developers read on:

- install docker machine
- golang version 1.12 and up
- clone repo under your $GOROOT directory, under src/
  e.g.
  my $GOPATH is /Users/agalushka/go
  creat the directory /src to keep your project repos
  /go/src/gitlab.com/flotechnologies/flo-firewriter
  
Simpler way to run this service on your dev machine is to run:

- mind the dev vs. prod certs and creds, obtain the mentioned secrets from 1Password

`docker-compose build` to build flo-device-service locally
`docker-compose up` to bring flo-device-service up locally
`docker-compose down` to bring it down 

- the service is simple and can be easily compiled and run on your machine as go binary
- to build: 

`GOOS=darwin/386 GOARCH=386 go build -a -o flo-firewriter-b .`

- to run
 
`./flo-firewriter-b`

- if you don't want to build the firehose binary, simply run:

`go run main.go`

- to profile follow steps from https://flaviocopes.com/golang-profiling/

### Configuration

For dev and production configuration consult with 1Password under `Engineering Team - Lvl 2 vault` 
`[DEV] Firehose` and `[PROD] Firehose`.
  
### Deployment and Operation

- commit to dev branch deploys the changes to dev env

- commit to master branch  deploys the changes to production env

Firehose is running in k8s dev and prod cluster

To deploy imgage from you machine:

- TBD

To start the service:

- TBD

To stop the service:

- TBD

To restart the service:

- TBD

To scale the service:

- TBD


## Access the service API
You have to be on VPN to reach the service
  
DEV base URL

https://flo-firewriter.flocloud.co

PROD base URL

https://flo-firewriter.flosecurecloud.com


### TODO:

- Figure out why mqtt stops sending msgs (currently firestore service restarts mqtt subscriber)
- implement shared subscription which will allow horizontal scaling
- implement throttling, write device telemetry to FS only if the mobile client of the device is online.