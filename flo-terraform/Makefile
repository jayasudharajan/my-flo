# Default env is always dev.
APP ?= lenses
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
FIND ?= $(shell which find)
COMMITSHA ?= DEV

.PHONY: help auth
help: ## Display this help screen (default)
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap-helm:
	$(HELM) init --client-only --wait
	$(HELM) repo add lensesio https://lensesio.github.io/kafka-helm-charts/
	$(HELM) repo update

debug-helm: environment-dev
	$(HELM) ls
	$(HELM) template ./k8s/$(APP) -f k8s/pipeline.yaml --namespace=$(APP)

deploy-lenses:
	$(HELM) init --upgrade --wait --force-upgrade
	$(HELM) upgrade \
		$(APP) \
		lensesio/$(APP) \
		--namespace=$(APP) \
		--install \
		--debug \
		--set environment=$(ENV) \
		--values ./dev/charts/lenses/values.yaml \
		--set-file lenses.license="$(LENSES_LICENSE)" \
		--set lenses.security.defaultUser.username="$(LENSES_DEFAULT_USER_USERNAME)" \
		--set lenses.security.defaultUser.password="$(LENSES_DEFAULT_USER_PASSWORD)" \
		--set lenses.security.ldap.password="${LENSES_LDAP_USER_PASSWORD}" \
		--wait --timeout $(HELM_DEPLOY_TIMEOUT)
