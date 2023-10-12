# Notification Router
![img](http://makeameme.org/media/created/notifications-notifications-everywhere.jpg)

Routing notifications to third party systems.

1. Email - Sendwithus
2. Push notifications - Apple
3. Sms - Twilio
4. Woice - Twilio 


# Developer's Quickstart:
## Ensure your git is configured to get submodules:
```
git config --global alias.pullall '!f(){ git pull "$@" && git submodule update --init --recursive; }; f'
```

## Fork this repo & clone your own fork
```
git@github.com:<yourname>/flo-notification-router.git
```

## Develop
You can write code in your faviourite IDE, as well as run Debug locally.
But before you push your code to dev branch you must test everything in docker.


## Get AWS Cli (Linux/MaOS):
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
export AWS_ACCESS_KEY_ID="YourKeyRightHere"
export AWS_SECRET_ACCESS_KEY="YourSecretRightHere" 
export ...
```
Don't forget to restart your shell after updating those ^

## Build & Start Project in Docker
In project root dir:
```
docker-compose run build
docker-compose build --force-rm --no-cache
docker-compose run local
```
Logs will appear in logs/

##### Get Submodule
```bash
cd flo-foobar-service
git submodule add git@github.com:FloTechnologies/flo-app-templates.git .app
git submodule update --init --recursive --remote
```
