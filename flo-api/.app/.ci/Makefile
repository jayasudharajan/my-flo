all: build local

.PHONY: clean build bake login

run: dev
stop: clean

deploy: build bake

build:
	docker-compose run build

bake:
	docker-compose build --force-rm app

local:
	docker-compose run --service-ports local

dev:
	@docker-compose run --service-ports dev

test:
	docker-compose run --service-ports test


clean:
	docker-compose down && docker-compose kill
	rm -rf target/

purge: clean
	(docker ps -a | awk '{print $1}'| xargs docker rm -f) || exit 0
	(docker images | awk '{print $3}'| xargs docker rmi -f) || exit 0


login:
	$(shell aws ecr get-login --profile=flo-dev --no-include-email)
