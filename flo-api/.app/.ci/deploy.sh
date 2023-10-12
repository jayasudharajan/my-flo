#!/bin/bash
source .ci/.env.rc
set -euo pipefail

set -x

#### Container build ####

# This is required to push Dockerfile with a right build number, so we can roll back to a specific build (and not latest)
if [[ -f Dockerfile ]]; then
  sed -i "s/:latest/:${CI_PIPELINE_ID}/g" Dockerfile
fi

if [[ -f Dockerfile-artifact && -f Dockerrun.aws.json ]]; then
  sed -i "s/:latest/:artifact-${CI_PIPELINE_ID}/g" Dockerrun.aws.json
elif [[ -f Dockerrun.aws.json ]]; then
  sed -i "s/:latest/:${CI_PIPELINE_ID}/g" Dockerrun.aws.json
fi

# Make .app submodule an actual directory.
git rm --cached .app
git rm .gitmodules

rm -rf .app/.git

# Remove unneeded files
rm -rf image


# In case we don't have .ebextensions
mkdir -p $BUILD_ROOT/.ebextensions/

# Copy .ebextentions
cp -R $BUILD_ROOT/.app/.ebextensions/* $BUILD_ROOT/.ebextensions/

# Add everything to stage
git add .
########################

# TODO Add release notation so docker images will be tagged with "release"
if [[ $ENVIRONMENT != "dev" ]]
then
  unset AWS_ACCESS_KEY_ID && unset AWS_SECRET_ACCESS_KEY
  if [[ $ENVIRONMENT == "prod" ]]
  then
    # Add production profile
    echo -e "[flo-${ENVIRONMENT}]\naws_access_key_id=$AWS_ACCESS_KEY_ID_PROD\naws_secret_access_key=$AWS_SECRET_ACCESS_KEY_PROD\n" > ~/.aws/credentials
    eb init ${CI_PROJECT_NAME} --profile flo-${ENVIRONMENT} --region ${AWS_REGION_PROD} --platform docker-17.03.1-ce
  elif [[ $ENVIRONMENT == "mgmt" ]]
  then
    echo -e "[flo-${ENVIRONMENT}]\naws_access_key_id=$AWS_ACCESS_KEY_ID_MGMT\naws_secret_access_key=$AWS_SECRET_ACCESS_KEY_MGMT\n" > ~/.aws/credentials
    eb init ${CI_PROJECT_NAME} --profile flo-${ENVIRONMENT} --region ${AWS_REGION} --platform docker-18.06.1-ce
  fi

else
  eb init ${CI_PROJECT_NAME} --profile flo-dev --region ${AWS_REGION} --platform docker-17.03.1-ce
fi

log_deployment "START" && eb deploy --staged ${CI_PROJECT_NAME}-${ENVIRONMENT} --profile flo-${ENVIRONMENT} --message "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}.${CI_PIPELINE_ID} (${CI_COMMIT_MESSAGE})" --label "${BUILD_TIMESTAMP}.${CI_PIPELINE_ID}" --timeout 20 | grep "update completed successfully" && log_deployment "SUCCESS" || (log_deployment "FAIL" && exit 1)

echo "Saving EB app config"
eb config save --cfg "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}"
eb config put "${CI_PROJECT_NAME}.${BUILD_TIMESTAMP}"

# unstaging changes
git reset --hard
