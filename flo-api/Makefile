APP ?= flo-api

# Default env is always dev. This can be overriden
ENV ?= dev
AWS_REGION ?= us-west-2
EB_DEPLOY_TIMEOUT ?= 15
HELM_CHART ?= $(APP)
HELM_DEPLOY_TIMEOUT ?= 180
HELM_HISTORY_MAX ?= 3
HELM_HISTORY_MAX ?= 3
HELM_RELEASE_NAME ?= $(APP)
K8S_NAMESPACE ?= $(APP)
DOCKER_IMAGE ?= $(CI_REGISTRY_IMAGE)
DOCKER_REGISTRY ?= registry.gitlab.com/flotechnologies
DOCKER_TAG ?= latest
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)
CURL ?= $(shell which curl)
NODE_ENV ?= development
# NPM ?= $(COMPOSE) run --rm npm --node-env=$(NODE_ENV)
# GRADLE ?= $(COMPOSE) run --rm gradle
GIT ?= $(COMPOSE) run --rm git
RUN ?= $(COMPOSE) run --rm --service-ports run --node-env=$(NODE_ENV) run
EB = $(DOCKER) run --rm -t -v $(AWS_CREDS)/credentials:/root/.aws/credentials -v $(CURRENT_DIR):/src --workdir /src coxauto/aws-ebcli eb
EB_INIT ?= $(EB) init $(APP) --region=${AWS_REGION} --platform docker-18.06.1-ce
EB_DEPLOY ?= $(EB) deploy $(APP)-$(ENV) --staged
AWSCLI = $(DOCKER) run -v $(AWS_CREDS)/credentials:/root/.aws/credentials -v $(CURRENT_DIR):/src --workdir /src --rm --tty coxauto/aws-ebcli aws
AWSCLI_SH = $(DOCKER) run --rm -v $(AWS_CREDS)/credentials:/root/.aws/credentials -v $(CURRENT_DIR):/src --workdir /src --rm --tty coxauto/aws-ebcli
HELM ?= $(shell which helm)

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

prep-beanstalk:
	mkdir -pv $(BUILD_ROOT)/.ebextensions
	cp -R $(BUILD_ROOT)/.app/.ebextensions/* $(BUILD_ROOT)/.ebextensions

build:
	$(COMPOSE) run build
	$(COMPOSE) $(@) --pull app

tag:
	$(DOCKER) tag $(DOCKER_REGISTRY)/$(APP) $(DOCKER_REGISTRY)/$(APP):latest
	$(DOCKER) tag $(DOCKER_REGISTRY)/$(APP) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)

save-image:
	mkdir -p image
	$(DOCKER) save $(AWS_ECR_REPOSITORY)/$(CI_PROJECT_NAME) > image/$(CI_PROJECT_NAME)_$(CI_PIPELINE_ID).tar

install: docker ## Install npm packages using docker-based npm
	$(NPM) $(@)

audit: docker ## Install npm packages using docker-based npm
	$(NPM) $(@) fix

test: docker ## Run test task using docker-based npm
	./.app/.ci/test.sh

run: serve
serve: docker ## Run serve task using docker-based npm
	$(RUN) $(@)

watch: docker ## Run watch task using docker-based npm
	$(RUN) $(@)

watch-test: docker ## Run watch-test task using docker-based npm
	$(RUN) $(@)

watch-debug: docker ## Run watch-debug task using docker-based npm
	$(RUN) $(@)
	$(COMPOSE) -f docker-compose-full.yml down

up: docker build ## Build and run application as it would be run in production (from image)
	$(COMPOSE) $(@)

down: docker ## Stop application if running in the background
	$(COMPOSE) $(@)

pull: docker
	$(COMPOSE) $(@) --quiet || true
	$(COMPOSE) $(@) --quiet || true

push: docker
	$(DOCKER) load < image/$(CI_PROJECT_NAME)_$(CI_PIPELINE_ID).tar
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):latest
	$(DOCKER) $(@) $(DOCKER_REGISTRY)/$(APP):$(DOCKER_TAG)

debug-helm:
	$(HELM) template \
		./k8s/$(HELM_CHART) \
		--name $(HELM_RELEASE_NAME) \
		--values k8s/pipeline.yaml \
		--set environment=$(ENV) \
		--namespace=$(K8S_NAMESPACE)

deploy:
	$(HELM) upgrade \
		$(HELM_RELEASE_NAME) \
		./k8s/$(HELM_CHART) \
		--install \
		--values ./k8s/pipeline.yaml \
		--values ./k8s/extra-$(ENV).yaml \
		--set environment=$(ENV) \
		--namespace=$(K8S_NAMESPACE) --create-namespace \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)s

deploy-eb:
	./.app/.ci/deploy.sh

deploy-status:
	$(HELM) history --max $(HELM_HISTORY_MAX) $(HELM_RELEASE_NAME)
	$(HELM) status $(HELM_RELEASE_NAME)

environment:
	kube-svc-ctl generate-svc-config -service $(APP) -tag "${CI_PIPELINE_ID}" > ./k8s/pipeline.yaml


clean: down ## Remove build arifacts & related images
	rm -rf node_modules
	$(COMPOSE) kill
	$(DOCKER) rmi -f $$($(DOCKER) images -f "dangling=true" -q)

test-aws-creds:
	$(AWSCLI_SH) find /root/.aws
	$(AWSCLI) sts get-caller-identity

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
