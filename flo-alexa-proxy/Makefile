STAGE ?= dev
REGION ?= us-west-2

# Default env is always dev.
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
SLS ?= $(shell which sls)
AWS ?= $(shell which aws)
NPM ?= $(shell which npm)
YARN ?= $(shell which yarn)

# NOTE: make sure you run v14 of node.js: nvm install 14 && nvm use 14
install: ## install local dependencies for local sls testing
	$(NPM) install -g serverless
	$(YARN) install

push:
	$(SLS) deploy --stage $(STAGE) --region $(REGION)

run: stop ## Run all locally, point to dev
	$(SLS) offline start --stage 'local'

debug: ## Run all locally & point to local lambda. SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4505
	ALEXA_LAMBDA='http://localhost:4002/flo-alexa-local-versioned' $(SLS) offline start --stage 'local'

stop: ## Stop running task
	@(pkill -f 'sls' && echo 'sls stopped' || echo 'sls not running')

check: ## direct invoke of a function
	$(SLS) invoke local -f ping

check-remote: ## direct invoke of a function
	$(SLS) invoke local -f ping --path src/functions/proxy/ping-mock.json

clean-docker: ## Clean docker
	@$(DOCKER) image prune -f
	@$(DOCKER) images -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) rmi -f {}
	@$(DOCKER) volume ls -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) volume rm -f {}
	@$(DOCKER) images -q -f "reference=$(IMAGE_NAME)*" | \
		xargs -I {} $(DOCKER) rmi -f {}