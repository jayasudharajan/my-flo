APP ?= flo-notification-router-v2

# Default env is always dev. This can be overriden
ENV ?= dev
AWS_REGION ?= us-west-2
BASE_PATH ?= $(shell pwd)
CURRENT_DIR ?= $(shell pwd)
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
GRADLE ?= $(COMPOSE) -f build-tools.yml run --rm gradle
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3
RUN ?= $(COMPOSE) -f build-tools.yml run --rm --service-ports run --node-env=$(NODE_ENV) run

.PHONY: help
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

run-dev: testdocker ## Run the application in DEV mode. Debug Port 5005. Reload on file changes.
	@./scripts/run-dev.sh

watch-tests: testdocker ## Run tests. Debug Port 5005. Reload on file changes.
	@./scripts/watch-tests.sh

run-tests: testdocker ## Run tests.
	@./scripts/run-tests.sh

build:
	$(COMPOSE) -f build-tools.yml $(@) --pull build
	$(COMPOSE) $(@) --pull app
	$(COMPOSE) $(@) --pull app-tag


dependencies-image: docker-compose
	ls -lah . && pwd
	$(COMPOSE) -f build-tools.yml build --pull dependencies || true

dependencies-image-push: docker-compose
	$(COMPOSE) -f build-tools.yml push dependencies || true

push: docker-compose
	$(COMPOSE) $(@)
	$(COMPOSE) -f build-tools.yml $(@) build || true

debug-helm: environment
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		$(APP) \
		./k8s/$(APP) \
		--install \
		--set environment=$(ENV) \
		--values $(BASE_PATH)/k8s/pipeline.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml


run-prod: testdocker ##  Run Production Docker image.
	@./scripts/run-prod.sh

prepare-build-image:
	$(DOCKER) build -f Dockerfile.build -t ${CI_REGISTRY_IMAGE}:build-latest .
	$(DOCKER) push ${CI_REGISTRY_IMAGE}:build-latest

# Ensures docker is installed - does not enforce version, please use latest
testdocker: docker-compose
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
