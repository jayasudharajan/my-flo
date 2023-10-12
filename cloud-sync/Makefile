APP ?= cloud-sync

# Default env is always dev.
ENV ?= dev
BUILD_TAG ?= local
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180s
HELM_HISTORY_MAX ?= 3
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
GO ?= $(COMPOSE) -f build-tools.yml run --rm go
COMMITSHA ?= DEV
COMMITTIME ?= NONE
ENVSUBST ?= envsubst "`printf '${%s} ' $(bash -c "compgen -A variable")`"

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build inside docker
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg COMMITSHA=$(COMMITSHA) --build-arg COMMITTIME=$(COMMITTIME) -f Dockerfile.build .

debug: ## start all db & run in remote debug mode
	@(rm -f ./src/src)
	@(rm -rf ./db/tmp/kafka ./db/tmp/zookeeper)
	$(COMPOSE) -f docker-compose.yml -f docker-compose.debug.yml up --remove-orphans

run: build ## Run inside docker
	$(COMPOSE) -f docker-compose.yml down --remove-orphans
	$(COMPOSE) -f docker-compose.yml up

run-new: clean-db run

run-cluster: build ## Run inside docker
	$(COMPOSE) -f docker-compose.cluster.yml down --remove-orphans
	$(COMPOSE) -f docker-compose.cluster.yml up

test: ## local test
	cd src && go test -v

stop: ## Stops docker instance
	$(COMPOSE) -f docker-compose.yml down --remove-orphans

clean-db: ## Clean local debug DBs
	rm -rf ./db/tmp

clean-docker: ## Clean docker
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

debug-helm: environment-dev
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		$(APP) \
		./k8s/$(APP) \
		--install \
		--set environment=$(ENV) \
		--values ${BASE_PATH}/k8s/pipeline.yaml \
		--values ${BASE_PATH}/k8s/$(ENV)-values.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP)
	$(HELM) status $(APP)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml
	cat ./k8s/pipeline.yaml

prepare-configuration:
	$(ENVSUB) < deployment/secrets.yaml > deployment/secrets.yaml
