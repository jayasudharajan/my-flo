APP ?= flo-firewriter

# Default env is always dev. This can be overriden
ENV ?= dev
AWS_CREDS ?= $(HOME)/.aws
AWS_REGION ?= us-west-2
AWSCLI = $(DOCKER) run -v $(AWS_CREDS)/credentials:/root/.aws/credentials -v $(CURRENT_DIR):/src --workdir /src --rm --tty coxauto/aws-ebcli aws
AWSCLI_SH = $(DOCKER) run --rm -v $(AWS_CREDS)/credentials:/root/.aws/credentials -v $(CURRENT_DIR):/src --workdir /src --rm --tty coxauto/aws-ebcli
BUILD_TAG ?= local
DOCKER_IMAGE ?= ${CI_REGISTRY_IMAGE}
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
GRADLE ?= $(COMPOSE) -f build-tools.yml run --rm gradle
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180s
HELM_HISTORY_MAX ?= 3
GO ?= $(COMPOSE) run --rm go
FIND ?= $(shell which find)
COMMIT_MESSAGE=$(strip $(CI_COMMIT_MESSAGE))
ENVSUBST ?= envsubst "`printf '${%s} ' $(bash -c "compgen -A variable")`"

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build inside docker
	$(DOCKER) build \
	    --build-arg CI_COMMIT_MESSAGE="$(COMMIT_MESSAGE)" \
	    --build-arg CI_COMMIT_SHA="$(CI_COMMIT_SHA)" \
	    --build-arg COMMIT_TIME="$(COMMIT_TIME)" \
	    --tag $(APP):$(BUILD_TAG) -f Dockerfile .

build-arm: ## Build inside docker
	$(DOCKER) build \
	    --build-arg CI_COMMIT_MESSAGE="$(COMMIT_MESSAGE)" \
	    --build-arg CI_COMMIT_SHA="$(CI_COMMIT_SHA)" \
	    --build-arg COMMIT_TIME="$(COMMIT_TIME)" \
	    --tag $(APP):$(BUILD_TAG) -f Dockerfile.arm64.build .

test: docker ## Run test task using docker
	$(GO) $(@) ./... -v -tags=unit

# Local dev scripts
docs: ## generates swagger documentation files
	@echo "$(OK_COLOR)==> Generating API documentation... $(NO_COLOR)"
	./scripts/tools/swagger.sh

run: docker ## Run serve task using docker
	$(GO) $(@) main.go

watch: docker ## Run watch task using docker
	$(RUN) run $(@)

watch-test: docker ## Run watch-test task using docker
	$(RUN) run $(@)

watch-debug: docker ## Run watch-debug task using docker
	$(RUN) run $(@)

up: docker build ## Build and run application as it would be run in production (from image)
	$(COMPOSE) $(@)

down: docker ## Stop application if running in the background
	$(COMPOSE) $(@)

pull:
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(BUILD_TAG)

push:
	$(DOCKER) tag $(APP):$(BUILD_TAG) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)

debug-helm:
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		$(APP) \
		--install \
		./k8s/$(APP) \
		--set environment=$(ENV) \
		--values ${BASE_PATH}/k8s/pipeline.yaml \
		--values ${BASE_PATH}/k8s/${ENV}-values.yaml \
		--namespace=$(APP) \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP) -n $(APP)
	$(HELM) status $(APP) -n $(APP)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml

prepare-configuration:
	$(ENVSUB) < deployment/secrets.yaml > deployment/secrets.yaml

clean: down ## Remove build arifacts & related images
	rm -rf node_modules
	$(COMPOSE) kill

# Ensures docker is installed - does not enforce version, please use latest
docker: docker-compose
ifeq (, $(DOCKER))
	$(error "Docker is not installed or incorrectly configured. https://www.docker.com/")
else
	@$(DOCKER) --version
endif

# Ensures docker-compose is installed - does not enforce.
docker-compose:
ifeq (, $(COMPOSE))
	$(error "docker-compose is not installed or incorrectly configured.")
else
	@$(COMPOSE) --version
endif

# Local dev scripts
swag: ## generates swagger documentation files
	@echo "$(OK_COLOR)==> Generating API documentation... $(NO_COLOR)"
	./scripts/tools/swagger.sh

dockerclean: docker ## Docker images removed
	@echo "$(OK_COLOR)==> Cleaning Docker Images$(NO_COLOR)"
	@$(COMPOSE) -f docker-compose.yml down --remove-orphans
	@$(DOCKER) image prune -f
	@$(DOCKER) images -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) rmi -f {}
	@$(DOCKER) volume ls -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) volume rm -f {}
	@$(DOCKER) images -q -f "reference=$(IMAGE_NAME)*" | \
		xargs -I {} $(DOCKER) rmi -f {}
