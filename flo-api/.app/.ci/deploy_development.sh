#!/bin/bash
source .ci/.env.rc
set -euo pipefail

#### Container build ####
# Run docker build
docker-compose build app | tee ${CI_ARTIFACTS_DIR}/logs/build.log
docker tag ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME} ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME}:latest
docker tag ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME} ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME}:${CI_PIPELINE_ID}

# This is required to push Dockerfile with a right build number, so we can roll back to a specific build (and not latest)
if [[ -f Dockerfile ]]; then
  sed -i "s/:latest/:${CI_PIPELINE_ID}/g" Dockerfile
fi

if [[ -f Dockerrun.aws.json ]]; then
  sed -i "s/:latest/:${CI_PIPELINE_ID}/g" Dockerrun.aws.json
fi

# Make .app submodule an actual directory.
git rm --cached .app
git rm .gitmodules

rm -rf .app/.git

# Add everything to stage
git add .
########################

docker push ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME}:latest
docker push ${AWS_ECR_REPOSITORY}/${CI_PROJECT_NAME}:${CI_PIPELINE_ID}

eb init ${CI_PROJECT_NAME} --region ${AWS_REGION} --platform docker-17.03.1-ce


for APP in ${EB_APPS[@]}
do
  log_deployment "START" && eb deploy --staged ${APP}-${ENVIRONMENT} --message "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}.${CI_PIPELINE_ID}" --label "${BUILD_TIMESTAMP}.${CI_PIPELINE_ID}" | tee /dev/tty | grep "update completed successfully" && log_deployment "SUCCESS" || (log_deployment "FAIL" && exit 1)
  echo "\nSaving app config"
  eb config save --cfg "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}"
  eb config put "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}"
done


#docker logout $AWS_ECR_REPOSITORY

# TODO: Deploy to Bintray
echo "Deploying to Bintray (dryrun)"
