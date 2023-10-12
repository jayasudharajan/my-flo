## Description
Responsible for saving ***telemetry data*** into ***Influxdb***.

## Technical Details

- This micro-service is build in Scala on top of Akka and uses request-per-actor model.
- Events are received from a Kafka cluster as:

```json
{
    "did": "8cc7aa027c8c",
    "wf": 6.0,
    "f": 0.6,
    "t": 51.8,
    "p": 43.8,
    "o": 1,
    "m": 1,
    "sw1": 0,
    "sw2": 0,
    "ts": 1454389517,
    "sm": 2,
    "zm": 1
}
```

## Sample telemetry data in Influxdb

```json
{
    "time": 1454389517000000000,    // in NANOSECONDS
    "did": "8cc7aa027c8c",
    "wf": 6.0,
    "f": 0.6,
    "t": 51.8,
    "p": 43.8,
    "o": 1,
    "m": 1,
    "sw1": 0,
    "sw2": 0,
    "ts": 1454389517,
    "sm": 2,
    "zm": 1
}
```

## Develop
You can write code in your faviourite IDE, as well as run Debug locally.
But before you push your code to dev branch you must test everything in docker.


## Get AWS Cli (Linux/MacOS):
_Skip this if your AWS toolchain works and up-to-date_
```
pip install --upgrade --user awscli
pip install --upgrade --user awsebcli
```

```
aws configure --profile=flo-dev
```
Follow instructions and enter:
- __AWS Access Key ID:__ Your Acess Key ID
- __AWS Secret Access Key:__ Your Secret Access Key
- __Default region name:__ us-west-2

Authenticate to docker registry:
```
eval $(aws ecr get-login --profile=flo-dev)
```

## Configure your local secrets:
Look in `docker-compose.yml` under `These variables need to exist in your local environment:`. 
They all need to be configured in your ~/.bashrc like this
```
export BINTRAY_USER="YourBintrayUser"
export BINTRAY_KEY="YourBintrayKey
export AWS_ACCESS_KEY_ID="YourKeyRightHere"
export AWS_SECRET_ACCESS_KEY="YourSecretRightHere"
...
```
Don't forget to restart your shell after updating those ^

## Build & Start Project in Docker
In project root dir:
```
docker-compose up --build --force-recreate
```
Logs will appear in logs/
