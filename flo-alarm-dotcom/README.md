# flo-alarm-dotcom service

Flo - Alarm.com integration.  SEE: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/2278064129/Alarm.com

## Docker Setup

Runs everything locally on docker and map (standard) ports to localhost.  API is mapped to port 8000

- Install docker
- `make build`
- `make run` or `make debug` (faster launch, no docker compile)
- wait until the log stop scrolling (everything is bootup & ready)
- to do a deep ping test: `curl -XPOST localhost:8080/ping`
- response should be http 200 with `status` field value `OK`

## Local Go Run/Debug

- Install `go 1.16+`
- Install `librdkafka`
- Install `delve`
- Load up all the required env var (SEE: vault service secret for `flo-alarm-dotcom` in appropriate env)
- build & run: `cd src && go mod tidy && go build && ./src`

## To generate new or rotate key

- Ensure you have openssl installed
- `private-key.pem` and `public-key.pem` is used to generate request token to ADC cloud, we share the `public-key.pem` file with ADC team
- to generate a private key: `openssl genrsa -aes256 -out private-key.pem 3072` (smaller key-sizes can be used for dev, 3072 should be the min for prod, too big & it's slow and increase payload size)
- type in your passcode, update it in 1pass & vault env var `FLO_ADC_RSA_PK_PWD` the code need this pwd along with the private key to sign JWTs
- from the above, we generate a public key `openssl rsa -in private-key.pem -pubout -out public-key.pem` and provide the above password
- replace the keys stored in `src/keys/<cloud-environment>` folder, at run-time, the `*appContext.Env` value will be used to build pem file path (`cloud-environment`)
- For context, SEE: https://answers.alarm.com/ADC/Partner/Partner_Tools_and_Services/Growth_and_Productivity_Services/Integrations/Alarm.com_Standard_API/Report_State_Device_Events
- Default private key pwd for development environment is checked in as default env var value `FLO_ADC_RSA_PK_PWD`, for prod pwd, see 1pass. Code allows for raw (none pwd private keys), it will log a notice during use. Please do not check in raw private key w/o pwd into git.