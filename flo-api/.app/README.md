# Quickstart


## Initialize Templates
#### In order to add your new scala `flo-foobar-service` app you need to:
##### Get Submodule
```bash
cd flo-foobar-service
git submodule add git@github.com:FloTechnologies/flo-app-templates.git .app
git submodule update --init --recursive --remote
```

##### Cleanup old structure
```bash
rm -rf .docker
rm -rf .ebextensions
rm Dockerfile
rm Dockerfile-base
rm Dockerrun.aws.json
rm circle.yml
rm docker-compose.yml
```

##### Create directory structure
`APPLICATION_PLATFORM` can be one of: `scala`,`golang`,`node`,`python` 
```bash
ln -s .app/.ci .ci
ln -s .app/.docker .docker
ln -s .app/Dockerfiles/Dockerfile-base-${APPLICATION_PLATFORM} Dockerfile-base
ln -s .app/Dockerrun.aws.json Dockerrun.aws.json
ln -s .app/.ci/Makefile Makefile
cp .app/Dockerfiles/Dockerfile Dockerfile
cp .app/docker-compose-samples/${APPLICATION_PLATFORM}-app.yml ./docker-compose.yml
cp .app/circle.yml ./
cp .app/.dockerignore ./
```

##### MANUAL: replace all tokens ({{ TOKEN_NAME }}), specifically to reflect your service name. Things like:
- docker-compose.yml `image: 098786959887.dkr.ecr.us-west-2.amazonaws.com/{{ app_name }}` -> `image: 098786959887.dkr.ecr.us-west-2.amazonaws.com/<YOUR_APP_NAME>`
- Dockerfile

##### Add everything to git
```bash
git add .
git commit -am "Enable .app template" 
```



## Build & your app in docker
```bash
make
```

## Configure ECR
- Create repository
- Configure permissions

## Configure CircleCI
- Add project
- Configure checkout key for submodules
- Configure env vars


