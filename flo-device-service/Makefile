APP ?= flo-device-service

# Default env is always dev. This can be overriden
ENV ?= dev
BUILD_TAG ?= local
AWS_REGION ?= us-west-2
DOCKER_IMAGE ?= ${CI_REGISTRY_IMAGE}
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180s
HELM_HISTORY_MAX ?= 3
GO ?= $(COMPOSE) run --rm -w "/src" --entrypoint "go" app
RUN ?= $(GO)
COMMITSHA ?= "$(shell git rev-parse --verify HEAD)"
COMMITTIME ?= "$(shell date -u +'%Y-%m-%dT%TZ')"
ENVSUBST ?= envsubst "`printf '${%s} ' $(bash -c "compgen -A variable")`"

.PHONY: help auth

# Required in EVERY project:   help, build, run
# ----------------------------------------------------------------------------------------------------------------------

help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the service inside docker
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg CI_COMMIT_SHA=$(COMMITSHA) --build-arg COMMIT_TIME=$(COMMITTIME) -f Dockerfile.build .

build-arm: ## Build the service inside docker for arm64
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg CI_COMMIT_SHA=$(COMMITSHA) --build-arg COMMIT_TIME=$(COMMITTIME) -f Dockerfile.arm64.build .

run:  ## Build and run the service inside docker (mounts cert/creds)
	$(COMPOSE) -f docker-compose.yml down --remove-orphans
	$(COMPOSE) -f docker-compose.yml up

stop:  ## Build and run the service inside docker (mounts cert/creds)
	$(COMPOSE) -f docker-compose.yml down --remove-orphans

test: docker ## Run test task using docker
	$(GO) $(@) -v

# Local dev scripts
docs: ## generates swagger documentation files
	@echo "$(OK_COLOR)==> Generating API documentation... $(NO_COLOR)"
	./scripts/tools/swagger.sh

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml

prepare-configuration:
	$(ENVSUB) < deployment/secrets.yaml > deployment/secrets.yaml

# Don't touch below, required by CICD
# ----------------------------------------------------------------------------------------------------------------------

pull:
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(BUILD_TAG)

push:
	$(DOCKER) tag $(APP):$(BUILD_TAG) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)

debug-helm: environment-dev
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		$(APP) \
		./k8s/$(APP) \
		--install \
		--set environment=$(ENV) \
		--values ./k8s/pipeline.yaml \
		--values ./k8s/$(ENV)-values.yaml \
		--namespace=$(APP) \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP) -n $(APP)
	$(HELM) status $(APP) -n $(APP)

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
