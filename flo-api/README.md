# Flo Public API (v1)

[![GitLab Pipeline](https://gitlab.flotech.co/core/flo-api/badges/dev/pipeline.svg)

======


# Running the Application

Ensure you have an up-to-date version of Docker on your machine.

To start the environment, at the root of the project directory, execute: `docker-compose -f docker-compose.local.yaml  build && docker-compose -f docker-compose.local.yaml up` .

## Applying code changes to the running environment

To apply any code changes to the running Docker environment, at the root of the project directory, execute `docker-compose -f docker-compose.local.yaml up -d --build`. 

This will rebuild and restart the `flo-api` container with any code or environment changes while leaving the other containers untouched.

## Bootstrapping 

To create all the Dynamo tables, admin user, system users (like notification-router, etc), and define ACL roles execute, in the project root directory, `docker exec flo-api bash -c "cd /app && gulp createtables && node scripts/createSystemUsers.js && node scripts/cacheAclRoles.js"` . 


# Quickstart

### Clean old node_modules
Ensure there is no node_modules directory in your source root


### Install required tools

```
sudo pip install awscli --upgrade
```

### Login to get the docker images

```
eval $(aws ecr get-login --no-include-email --profile=flo-dev)
```

## Create a case sensitive sparse bundle (MacOS only)
```
sudo hdiutil create -size 50g -type SPARSEBUNDLE -nospotlight -volname "container-cache" -fs "Case-sensitive Journaled HFS+" -imagekey sparse-band-size=262144 -verbose ~/Documents/container-cache.sparsebundle && sudo hdiutil attach -mountpoint ~/.container-cache ~/Documents/container-cache.sparsebundle

```

### Build, test and start a dev server:
```
docker-compose run build && docker-compose run test && docker-compose run dev 
```

###   Updating ACL roles 
- Go to the roles dir and find the roles file for the role you want to add permission too. Normally roles are the name of the application 
- add the resource and the permission you want to add to the role if it does not exist it needs to look like this:
```json
{
  "roles": "app.nator5000",
  "allows": [
    {
      "resources": ["ICD"],
      "permissions": ["handleDeviceAnomalyEvent", "retrieveByAnomalyTypeAndDateRange"]
    }
  ]
}
```
- permission are normally the name of the controller method you want to provide Authorization to
-  cd into the the repo root `cd /flo-api` and run this:
`gulp roles ` this will update the main roles and permission file for you `scripts/aclRoles.json`
- make sure the `FLO_API_ELASTICACHE_ENDPOINT` env var is pointing to the right environment and you are connected to the environment VPN cd into the project `cd /flo-api` and run this `node scripts/cacheAclRoles.js`
- make sure to promptly commit to the github and merge it to prevent someone over-writing the aclRolesCache  

### Running Locally
- Be sure of having node version `v6.13.1` and python version `>2.5 <3`
- Run `npm install` to install depencies
- Run `gulp | bunyan` to start the project
- The variable `ENFORCE_HTTPS` must be set to `false` (default `true`) to prevent the forced HTTPS redirect

### Unit Test 
- cp into the app root `cd /flo-api`
- prepare the source `gulp build`
- to run tests type `npm test` in terminal
- **Make Sure your local is pointing to local dynamo**  `http://localhost:4567/` otherwise you might overstress the Dev environment as follows:
```
export NODE_ENV=development
export FLO_API_AWS_DYNAMODB_PREFIX=local
export FLO_API_AWS_DYNAMODB_ENDPOINT=http://localhost:4567
export FLO_API_AWS_DYNAMODB_REGION=us-west-2
export FLO_API_HMAC_KEY=FLO_API_HMAC_KEY
```
- to run your test individually `cd flo-api` and  ` gulp build && ./node_modules/mocha/bin/mocha tests/mocha/services/device-anomaly/FooTest.js`


### Troubleshooting

If you have issues getting node-rdkafka library try this

```
CPPFLAGS=-I/usr/local/opt/openssl/include LDFLAGS=-L/usr/local/opt/openssl/lib npm install node-rdkafka
```

# Production Considerations

## Environment Variables

Beanstalk places several limitations on setting environment variables natively through the interface/API.

- **Keys** can contain any alphanumeric characters and the following symbols: `_ . : / + \ - @`. For compatibility with all platforms, limit environment properties to the following pattern: `[A-Z_][A-Z0-9_]*`
- **Values** can contain any alphanumeric characters, white space, and the following symbols: `_ . : / = + \ - @ ' "`
- **Keys** can contain up to 128 characters. Values can contain up to 256 characters.
- **Keys** and values are case sensitive.
- The combined size of all environment properties **cannot exceed 4,096 bytes** when stored as strings with the format key=value.

### Workaround for the Environment Variable limit

| Environment | S3 Path                                                                   |
| ----------- | ------------------------------------------------------------------------- |
| Production  | s3://flosecurecloud-config/flo-apps/flo-api/prod/prod-flo-api.env.json.gz |
| Developer   | s3://flocloud-config/flo-apps/flo-api/dev/dev-flo-api.env.json.gz         |

Flo API V1 has well over 100 necessary environment variables to define and hit
the current 4kiB Beanstalk var limitation. As a workaround, an encrypted,
gzipped JSON file of variables are stored in S3.  Normally these variables are
updated and placed in S3 via an Ansible script that also sets up and defines
the entire Beanstalk environment. In case one does not want to run the whole
Ansible workflow, the commands below will allow one to download and decrypt the
env file for update:

```
export ENV=dev  # dev or prod
export PATH_TO_TARGET=/path/somewhere   # pick a path
export CFORM_ENV_KEY=rochurachuareohu   # custom CloudForm key, ask DevOps

# Download data
aws --profile "${AWS_PROFILE}" s3 cp "${S3_ENV_FILE_PATH}" "${PATH_TO_TARGET}"
# Decrypt file
cat "${PATH_TO_TARGET}/${APP_ENV}-flo-api.env.json.gz | gzip -d | openssl aes-256-cbc -a -salt -d -k '${CFORM_ENV_KEY}' > "${PATH_TO_TARGET}/${APP_ENV}-flo-api.env.json"
# ...
# EDIT VALUES
# ...
# Encrypt file
openssl aes-256-cbc -a -salt -in "${PATH_TO_TARGET}/${APP_ENV}-flo-api.env.json" -k '${CFORM_ENV_KEY}' | gzip > "${PATH_TO_TARGET}/${APP_ENV}-api.env.json.$(date +%Y%m%d).gz"
aws --profile "${AWS_PROFILE}" s3 cp "${PATH_TO_TARGET}/${APP_ENV}-api.env.json.$(date +%Y%m%d).gz" "${S3_ENV_FILE_PATH}"
```
