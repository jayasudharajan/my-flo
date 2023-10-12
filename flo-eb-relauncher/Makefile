BINTRAY_KEY := 'test token'
BINTRAY_USER := 'testuser'
GRADLE := docker run --rm -it -u gradle -v "$(shell pwd):/app" -e BINTRAY_USER=$(BINTRAY_USER) -e BINTRAY_KEY=$(BINTRAY_KEY) -w /app gradle gradle

build:
	$(GRADLE) build

clean:
	$(GRADLE) clean

tasks:
	$(GRADLE) tasks

deploy: clean build
	sls deploy --aws-s3-accelerate --verbose $(ARGS)

deploy-prod: clean build
	sls deploy --aws-s3-accelerate --verbose -s prod

logs:
	sls logs -t -f eb-restarter-$(EB_SVC)
