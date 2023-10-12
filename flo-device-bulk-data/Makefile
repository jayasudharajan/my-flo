APP ?= flo-device-bulk-data

# Default env is always dev.
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
# NOTE: install nvm & make sure you're using node version 12
NPM ?= $(shell which npm)
TSC ?= $(shell which tsc)

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

run-compose: stop-compose ## Run inside docker 
	$(COMPOSE) up --build --force-recreate 

stop-compose: ## Stops docker instance
	$(COMPOSE) down --remove-orphans

run: run-compose ## Run all in docker image

install: ## Install npm dependency locally for local debug
	$(NPM) install

build: ## Build the code to -> ./lib for local debug
	$(TSC)

debug-dev: build ## Build & run locally, attaching to dev env with debugger port open
	ACCOUNT_ID=098786959887 \
	TELEMETRY_S3_BUCKET=flocloud-bulk-device-telemetry \
	LOGS_S3_BUCKET=flocloud-bulk-device-logs \
	$(NPM) run-script debug

debug: debug-dev

clean: clean-docker ## All clean targets

clean-docker: ## Clean docker
	@$(DOCKER) image prune -f
	@$(DOCKER) images -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) rmi -f {}
	@$(DOCKER) volume ls -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) volume rm -f {}
	@$(DOCKER) images -q -f "reference=$(IMAGE_NAME)*" | \
		xargs -I {} $(DOCKER) rmi -f {}