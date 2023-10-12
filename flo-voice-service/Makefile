APP ?= flo-voice-service

# Default env is always dev. This can be overriden
ENV ?= dev
BUILD_TAG ?= local
AWS_REGION ?= us-west-2
DOCKER_IMAGE ?= ${CI_REGISTRY_IMAGE}
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
GIT ?= $(COMPOSE) -f build-tools.yml run --rm git
GO ?= $(COMPOSE) -f build-tools.yml run --rm go
HELM ?= $(shell which helm)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3
ENVSUBST ?= envsubst "`printf '${%s} ' $(bash -c "compgen -A variable")`"

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

prepare-build-image:
	$(DOCKER) build --network host -f Dockerfile.run -t ${CI_REGISTRY_IMAGE}:${CI_PIPELINE_ID} .
	$(DOCKER) push ${CI_REGISTRY_IMAGE}:${CI_PIPELINE_ID}

kubectl-config:
	$(COMPOSE) up $(@)

deploy:
	cd /builds/flotechnologies/flo-voice-service
	$(HELM) upgrade \
		$(APP) \
		./k8s/$(APP) \
		--install \
		--set environment=$(ENV) \
		--values ./k8s/pipeline.yaml \
		--namespace=$(APP) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml

prepare-configuration:
	$(ENVSUB) < deployment/secrets.yaml > deployment/secrets.yaml

build: ## Build the service inside docker
	$(DOCKER) build --tag $(APP):$(BUILD_TAG) --build-arg COMMITSHA=$(COMMITSHA) --build-arg COMMITTIME=$(COMMITTIME) -f Dockerfile.build .
test: docker ## Run test task using docker
	$(GO) $(@) ./... -v -tags=unit

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

pull: docker
	$(COMPOSE) $(@) --quiet || true
	$(COMPOSE) -f build-tools.yml $(@) --quiet || true

push:
	$(DOCKER) tag $(APP):$(BUILD_TAG) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)


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
docs: ## generates swagger documentation files
	@echo "$(OK_COLOR)==> Generating API documentation... $(NO_COLOR)"
	./scripts/tools/swagger.sh

db-start: ## starts up Postgres in the docker container
	@echo "$(OK_COLOR)==> Starting Postgres DB... $(NO_COLOR)"
	./scripts/db/dev/start_db.sh

db-init: ## initializes Postgres DB schema, creates triggers
	@echo "$(OK_COLOR)==> Initializing Postgres DB... $(NO_COLOR)"
	./scripts/db/dev/init_db.sh

db-stop: ## shuts down Postgres DB
	@echo "$(OK_COLOR)==> Shutting down Postgres DB... $(NO_COLOR)"
	./scripts/db/dev/stop_db.sh

db-dump: ## dumps Postgres DB data
	@echo "$(OK_COLOR)==> Dumping Postgres DB data... $(NO_COLOR)"
	./scripts/db/dev/dump_db.sh

db-restore: ## restores Postgres DB from dump file
	@echo "$(OK_COLOR)==> Restoring Postgres DB from dump file... $(NO_COLOR)"
	./scripts/db/dev/restore_db.sh

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
