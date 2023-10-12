APP ?= flo-water-meter

# Default env is always dev.
ENV ?= dev
BUILD_TAG ?= local
CURRENT_DIR ?= $(shell pwd)
DOCKER_IMAGE ?= ${CI_REGISTRY_IMAGE}
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
GO ?= $(COMPOSE) -f build-tools.yml run --rm go
FIND ?= $(shell which find)
COMMITSHA ?= DEV

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build inside docker
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg COMMITSHA=$(COMMITSHA) -f Dockerfile.build .

run: build ## Run inside docker
	$(COMPOSE) -f docker-compose.yml down --remove-orphans
	$(COMPOSE) -f docker-compose.yml up

unit-test-ci: ## run unit test inside of docker, no db needed
	$(DOCKER) run --entrypoint "go" -e CGO_ENABLED=1 -e GOOS=linux -e GOARCH=amd64 $(DOCKER_REGISTRY)/$(APP):$(BUILD_TAG) test -v

unit-test-local: ## run any command inside the container this way. IE: ls -l /
	$(DOCKER) run --entrypoint "go" -e CGO_ENABLED=1 -e GOOS=linux -e GOARCH=amd64 $(APP):$(BUILD_TAG) test -v

stop: ## Stops docker instance
	$(COMPOSE) -f -docker-compose.yml down --remove-orphans

pull:
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(BUILD_TAG)

push:
	$(DOCKER) tag $(APP):$(BUILD_TAG) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)

debug-helm: environment
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		--install $(APP) \
		./k8s/$(APP) \
		--set environment=$(ENV) \
		--values $(BASE_PATH)/k8s/pipeline.yaml \
		--values $(BASE_PATH)/k8s/$(ENV)-values.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP) -n $(APP)
	$(HELM) status $(APP) -n $(APP)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml



clean: ## Clean docker
	@$(DOCKER) image prune -f
	@$(DOCKER) images -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) rmi -f {}
	@$(DOCKER) volume ls -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) volume rm -f {}
	@$(DOCKER) images -q -f "reference=$(IMAGE_NAME)*" | \
		xargs -I {} $(DOCKER) rmi -f {}
