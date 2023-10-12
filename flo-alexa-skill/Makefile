FUNC_NAME ?= flo-alexa-dev
COMMIT_HASH ?= unknown-hash
APPLICATION_ID ?= amzn1.ask.skill.d084a806-bcff-4ef8-b9b6-3261a0d70f13
FLO_API_URL ?= https://api-dev.flocloud.co/api
FLO_ALEXA_SMARTHOME_URL ?= https://flo-alexa-smarthome.flocloud.co

STAGE ?= local
APP ?= flo-alexa-skill
ENV_HASH_APPEND = '. | .Variables.COMMIT_HASH="$(COMMIT_HASH)" | .Variables.APPLICATION_ID="$(APPLICATION_ID)" | .Variables.FLO_API_URL="$(FLO_API_URL)" | .Variables.FLO_ALEXA_SMARTHOME_URL="$(FLO_ALEXA_SMARTHOME_URL)"'
ENV_JSON ?= $(shell cat .env.json | jq -c $(ENV_HASH_APPEND))
FUNC_RUN_TIME ?= nodejs14.x

# Default env is always dev.
SLS ?= $(shell which sls)
AWS ?= $(shell which aws)
NPM ?= $(shell which npm)
ZIP ?= $(shell which zip)
UNZIP ?= $(shell which unzip)

# NOTE: make sure you run v14 of node.js: nvm install 14 && nvm use 14
install: ## build locally (current box)
	$(NPM) install -g serverless

build: ## build locally (current box)
	$(NPM) install

test: ## test locally (current box)
	$(NPM) run test

stop: ## Stop running sls tasks
	@(pkill -f 'sls' && echo 'sls stopped' || echo 'sls not running')

run: build ## Run lambda locally using sls
	APPLICATION_ID=$(APPLICATION_ID) FLO_API_URL=$(FLO_API_URL) FLO_ALEXA_SMARTHOME_URL=$(FLO_ALEXA_SMARTHOME_URL) $(SLS) offline start --stage $(STAGE)

debug: ## Run lambda locally using sls
	APPLICATION_ID=$(APPLICATION_ID) FLO_API_URL=$(FLO_API_URL) FLO_ALEXA_SMARTHOME_URL='http://localhost:8888' $(SLS) offline start --stage $(STAGE)

check: ## Quick local ping test
	$(SLS) invoke local -f 'versioned' --path test_input/ping.json

#NOTE: not using sls because this lambda was created and published to alexa w/o SLS, keeping thing "as is" with publishing.
#SLS is used for local debugging only
push-update: build pack-manual ## update current aws lambda version with this code
	$(AWS) lambda update-function-code --function-name $(FUNC_NAME) --zip-file 'fileb://../$(APP).zip'

#SEE: https://docs.aws.amazon.com/cli/latest/reference/lambda/update-function-configuration.html
push-cfg: ## COMMIT_HASH=$(git rev-parse --short HEAD),
	$(AWS) lambda update-function-configuration --function-name $(FUNC_NAME) --runtime $(FUNC_RUN_TIME) --environment '$(ENV_JSON)'

push-version: ## create a new version of aws lambda code and config with current code and config
	$(AWS) lambda publish-version --function-name $(FUNC_NAME)

#NOTE: to exclude with wild card, use: -x '*.git*' -x '*.json' -x '*.lock' -x '.*' -x '_check' -x '*.md'
pack-manual: pack-clean ## Run inside docker
	$(ZIP) -r '../$(APP).zip' *.js node_modules

pack-check: ## Run inside docker
	$(UNZIP) '../$(APP).zip' -d ../_check

pack-clean: ## Run inside docker
	@rm -rf ../$(APP).zip ../_check