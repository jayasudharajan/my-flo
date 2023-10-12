#!/bin/bash
source .ci/.env.rc
set -euo pipefail


#### Container build ####
# Run docker build
docker-compose build app | tee ${CIRCLE_ARTIFACTS}/logs/build.log
docker tag ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME} ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME}:latest
docker tag ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME} ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME}:${CIRCLE_BUILD_NUM}

# This is required to push Dockerfile with a right build number, so we can roll back to a specific build (and not latest)
if [[ -f Dockerfile ]]; then
  sed -i "s/:latest/:${CIRCLE_BUILD_NUM}/g" Dockerfile
fi

if [[ -f Dockerrun.aws.json ]]; then
  sed -i "s/:latest/:${CIRCLE_BUILD_NUM}/g" Dockerrun.aws.json
fi

# Make .app submodule an actual directory.
git rm --cached .app
git rm .gitmodules

rm -rf .app/.git

# Add everything to stage
git add .
########################

docker push ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME}:latest
docker push ${AWS_ECR_REPOSITORY}/${CIRCLE_PROJECT_REPONAME}:$CIRCLE_BUILD_NUM

# Change the default profile to management.
echo -e "[flo-mgmt]\naws_access_key_id=$AWS_ACCESS_KEY_ID_MGMT\naws_secret_access_key=$AWS_SECRET_ACCESS_KEY_MGMT\n" > ~/.aws/credentials

eb init ${CIRCLE_PROJECT_REPONAME} --profile flo-mgmt --region ${AWS_REGION_MGMT} --platform docker-17.09.1-ce

for APP in ${EB_APPS[@]}
do
  log_deployment "START" && eb deploy --staged ${APP}-mgmt --profile flo-mgmt --message "${APP}.$BUILD_TIMESTAMP.$CIRCLE_BUILD_NUM" --label "$BUILD_TIMESTAMP.$CIRCLE_BUILD_NUM" --timeout 20 | tee /dev/tty | grep "update completed successfully" && log_deployment "SUCCESS" || (log_deployment "FAIL" && exit 1)
  echo "\nSaving app config"
  eb config save --cfg "${APP}.${BUILD_TIMESTAMP}"
  eb config put "${APP}.${BUILD_TIMESTAMP}"
done
