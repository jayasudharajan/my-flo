# FLO Localization Service

[![Build Status](https://gitlab.com/flotechnologies/flo-localization-service/badges/master/build.svg)](https://gitlab.com/flotechnologies/flo-localization-service/commits/master) [![Coverage Report](https://gitlab.com/flotechnologies/flo-localization-service/badges/master/coverage.svg)](https://gitlab.com/flotechnologies/flo-localization-service/commits/master) [![Go Report Card](https://goreportcard.com/badge/gitlab.com/flotechnologies/flo-localization-service)](https://goreportcard.com/report/gitlab.com/flotechnologies/flo-localization-service)


## What you need on dev:

### Mac developers read on:

- install docker machine
- psql
- golang version 1.12 and up
- clone repo under your $GOROOT directory, under src/
  e.g.
  my $GOPATH is /Users/agalushka/go
  creat the directory /src to keep your project repos
  /go/src/gitlab.com/flotechnologies/flo-localization-service
  
Simpler way to run this service on your dev machine is to run:

`docker-compose build` to build flo-localization-service locally
`docker-compose up` to bring flo-localization-service up locally
`docker-compose down` to bring it down 
  
## How to run:

- this project uses makefile
- `make run` brings up the service
  
## Access the service API

You have to be on VPN to reach the service
  
DEV base URL

https://flo-localization-service-dev.flocloud.co/

PROD base URL

http://flo-localization-service.flosecurecloud.com

## How to generate docs

install go swag, you can simply download it's binary https://github.com/swaggo/swag/releases

run

`make swag`
 
assuming you have binary installed to e.g. ~/swag_1.5.0_Darwin_x86_64/swag

## Documentation

Supported delivery types:

	"sms":        true
	"push":       true
	"display":    true
	"email":      true
	"phone":      true
	"alexa":      true
	"googleHome": true

Swagger docs

https://flo-localization-service.dev.flocloud.co/swagger/index.html

flo-localization-service.flosecurecloud.com/swagger/index.html

[Localization Wiki Page](https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/774307868/Localization+Service)

  