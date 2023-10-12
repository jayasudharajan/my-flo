APP ?= flo-weather

# Default env is always dev.
ENV ?= dev
BUILD_TAG ?= local
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
GO ?= $(COMPOSE) -f build-tools.yml run --rm go
COMMITSHA ?= DEV
COMMITTIME ?= NONE

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build inside docker
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg COMMITSHA=$(COMMITSHA) --build-arg COMMITTIME=$(COMMITTIME) -f Dockerfile.build .

run: build ## Run inside docker
	$(COMPOSE) -f docker-compose.yml down --remove-orphans
	$(COMPOSE) -f docker-compose.yml up

stop: ## Stops docker instance
	$(COMPOSE) -f docker-compose.yml down --remove-orphans

clean: ## Clean docker
	@$(DOCKER) image prune -f
	@$(DOCKER) images -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) rmi -f {}
	@$(DOCKER) volume ls -q -f "dangling=true" | \
		xargs -I {} $(DOCKER) volume rm -f {}
	@$(DOCKER) images -q -f "reference=$(IMAGE_NAME)*" | \
		xargs -I {} $(DOCKER) rmi -f {}

# Local dev scripts
docs: ## generates swagger documentation files
	@echo "$(OK_COLOR)==> Generating API documentation... $(NO_COLOR)"
	./generate-docs.sh

# Below tags are for CICD only

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
		$(APP) \
		./k8s/$(APP) \
		--install \
		--set environment=$(ENV) \
		--values ${BASE_PATH}/k8s/pipeline.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP) -n $(APP)
	$(HELM) status $(APP) -n $(APP)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml
