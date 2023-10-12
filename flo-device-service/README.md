# FLO Device Service

[![Build Status](https://gitlab.com/flotechnologies/flo-device-service/badges/master/build.svg)](https://gitlab.com/flotechnologies/flo-device-service/commits/master) [![Coverage Report](https://gitlab.com/flotechnologies/flo-device-service/badges/master/coverage.svg)](https://gitlab.com/flotechnologies/flo-device-service/commits/master) [![Go Report Card](https://goreportcard.com/badge/gitlab.com/flotechnologies/flo-device-service)](https://goreportcard.com/report/gitlab.com/flotechnologies/flo-device-service)


## what you need on dev:

### Mac developers read on:

- install docker machine
- psql
- install librdkafka in order to use legit kafka go library by confluent:
  https://github.com/confluentinc/confluent-kafka-go#installing-librdkafka
  `brew install librdkafka pkg-config`
- golang version 1.12 and up
- clone repo under your $GOROOT directory, under src/
  e.g.
  my $GOPATH is /Users/agalushka/go
  creat the directory /src to keep your project repos
  /go/src/gitlab.com/flotechnologies/flo-device-service
  
Simpler way to run this service on your dev machine is to run:

`docker-compose build` to build flo-device-service locally
`docker-compose up` to bring flo-device-service up locally
`docker-compose down` to bring it down 
  
## how to run:

- this project uses makefile
- `make run` brings up   
  
## Access the service API
You have to be on VPN to reach the service
  
DEV base URL

https://flo-device-service.flocloud.co

PROD base URL

https://flo-device-service.flosecurecloud.com

## How to generate docs

install go swag, you can simply download it's binary https://github.com/swaggo/swag/releases

run

`make swag`
 
assuming you have binary installed to e.g. ~/swag_1.5.0_Darwin_x86_64/swag

## Documentation

Swagger docs

flo-device-service.flocloud.co/swagger/index.html

flo-device-service.flosecurecloud.com/swagger/index.html
  
  
  