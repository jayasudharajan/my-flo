APP ?= flo-notification-api
ENV ?= dev
AWS_REGION ?= us-west-2
COMPOSE ?= $(shell which docker-compose)
DOCKER ?= $(shell which docker)
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
GRADLE ?= $(COMPOSE) -f build-tools.yml run --rm gradle
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3

.PHONY: help
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: run-dev
run-dev: testdocker ## Run the application in DEV mode. Debug Port 5005. Reload on file changes.
	@./scripts/run-dev.sh

.PHONY: watch-tests
watch-tests: testdocker ## Run tests. Debug Port 5005. Reload on file changes.
	@./scripts/watch-tests.sh

.PHONY: run-tests
run-tests: testdocker ## Run tests.
	@./scripts/run-tests.sh

.PHONY: run-build
build:
	$(COMPOSE) -f build-tools.yml $(@) --pull build
	$(COMPOSE) $(@) --pull app
	$(COMPOSE) $(@) --pull app-tag

build-with-docker:
	$(DOCKER) build --network host \
		--file Dockerfile.build \
		--tag "$(CI_REGISTRY_IMAGE):build-latest" \
		.
	$(DOCKER) build --network host \
		--build-arg CI_COMMIT_SHA=$(CI_COMMIT_SHA) \
		--build-arg COMMIT_TIME=$(COMMIT_TIME) \
		--file Dockerfile.run \
		--tag "$(CI_REGISTRY_IMAGE):latest" \
		.
	$(DOCKER) tag "$(CI_REGISTRY_IMAGE):latest" "$(CI_REGISTRY_IMAGE):$(CI_PIPELINE_ID)"

pull: docker-compose
	$(COMPOSE) $(@) --quiet || true
	$(COMPOSE) -f build-tools.yml $(@) --quiet || true

push: docker-compose
	$(COMPOSE) $(@)
	$(COMPOSE) -f build-tools.yml $(@) build || true

debug-helm: environment-dev
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy:
	$(HELM) upgrade \
		--install $(APP) \
		./k8s/$(APP) \
		--set environment=$(ENV) \
		--values ./k8s/${ENV}-values.yaml \
		--values ./k8s/pipeline.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(APP) -n $(APP)
	$(HELM) status $(APP) -n $(APP)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml

.PHONY: prod
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
